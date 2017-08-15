//
//  TorController.m
//  OnionBrowser
//
//  Created by Mike Tigas on 9/5/12.
//
//

#import "TorController.h"
#import "NSData+Conversion.h"
#import "AppDelegate.h"
#import "Reachability.h"
#import "Ipv6Tester.h"
#import <QuartzCore/QuartzCore.h>

@implementation TorController {
    int nbrFailedAttempts;
}

#define STATUS_CHECK_TIMEOUT 3.0f
#define TOR_STATUS_WAIT 1.0f
#define CONTROL_PORT_RECONNECT_WAIT 1.0f
#define MAX_FAILED_ATTEMPTS 10

@synthesize
didFirstConnect,
torControlPort = _torControlPort,
torSocksPort = _torSocksPort,
torThread = _torThread,
torCheckLoopTimer = _torCheckLoopTimer,
torStatusTimeoutTimer = _torStatusTimeoutTimer,
mSocket = _mSocket,
controllerIsAuthenticated = _controllerIsAuthenticated,
connectionStatus = _connectionStatus,
connLastAutoIPStack = _connLastAutoIPStack
;

-(id)init {
    if (self=[super init]) {
        _torControlPort = (arc4random() % (57343-49153)) + 49153;
        _torSocksPort = (arc4random() % (65534-57344)) + 57344;
        
        _controllerIsAuthenticated = NO;
        _connectionStatus = CONN_STATUS_NONE;
        
        _currentCircuits = [[NSMutableArray alloc] init];
        
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        NSInteger ipSetting = [[appDelegate.getSettings valueForKey:@"tor_ipv4v6"] integerValue];
        if (ipSetting == OB_IPV4V6_AUTO) {
            NSInteger ipv6_status = [Ipv6Tester ipv6_status];
            if (ipv6_status == TOR_IPV6_CONN_ONLY) {
                _connLastAutoIPStack = CONN_LAST_AUTO_IPV4V6_IPV6;
            } else if (ipv6_status == TOR_IPV6_CONN_DUAL) {
                _connLastAutoIPStack = CONN_LAST_AUTO_IPV4V6_DUAL;
            } else {
                _connLastAutoIPStack = CONN_LAST_AUTO_IPV4V6_IPV4;
            }
        } else {
            _connLastAutoIPStack = CONN_LAST_AUTO_IPV4V6_MANUAL;
        }
        
        // listen to changes in connection state
        // (tor has auto detection when external IP changes, but if we went
        //  offline, tor might not handle coming back gracefully -- we will SIGHUP
        //  on those)
        Reachability* reach = [Reachability reachabilityForInternetConnection];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(reachabilityChanged)
                                                     name:kReachabilityChangedNotification
                                                   object:nil];
        [reach startNotifier];
    }
    return self;
}

-(void)startTor {
    // Starts or restarts tor thread.
    
    if (_torCheckLoopTimer != nil) {
        [_torCheckLoopTimer invalidate];
    }
    if (_torStatusTimeoutTimer != nil) {
        [_torStatusTimeoutTimer invalidate];
    }
    if (_torThread != nil) {
        [_torThread.tor cancel];
        _torThread = nil;
    }
    
    _torThread = [[TorWrapper alloc] init];
    [_torThread start];
    
    _torCheckLoopTimer = [NSTimer scheduledTimerWithTimeInterval:0.15f
                                                          target:self
                                                        selector:@selector(activateTorCheckLoop)
                                                        userInfo:nil
                                                         repeats:NO];
}

- (void)hupTor {
    if (_torCheckLoopTimer != nil) {
        [_torCheckLoopTimer invalidate];
    }
    if (_torStatusTimeoutTimer != nil) {
        [_torStatusTimeoutTimer invalidate];
    }
    
    [_mSocket writeString:@"SIGNAL HUP\n" encoding:NSUTF8StringEncoding];
    _torCheckLoopTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f
                                                          target:self
                                                        selector:@selector(activateTorCheckLoop)
                                                        userInfo:nil
                                                         repeats:NO];
}

- (void)requestTorInfo {
#ifdef DEBUG
    NSLog(@"[Tor] Requesting Tor info (getinfo orconn-status)" );
#endif
    
    // Reset circuits info
    _currentCircuits = [[NSMutableArray alloc] init];

    [_mSocket writeString:@"getinfo circuit-status\n" encoding:NSUTF8StringEncoding];
}

- (void)requestNewTorIdentity {
#ifdef DEBUG
    NSLog(@"[Tor] Requesting new identity (SIGNAL NEWNYM)" );
#endif
    [_mSocket writeString:@"SIGNAL NEWNYM\n" encoding:NSUTF8StringEncoding];
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate.logViewController logInfo:@"[Tor] Requesting new identity"];
}


#pragma mark -
#pragma mark App / connection status callbacks

- (void)reachabilityChanged {
    Reachability* reach = [Reachability reachabilityForInternetConnection];
    
    if (reach.currentReachabilityStatus != NotReachable) {
#ifdef DEBUG
        NSLog(@"[Tor] Reachability changed (now online), sending HUP" );
#endif
        
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        [appDelegate.logViewController logInfo:@"[Tor] Reachability changed (now online)"];
        
        // TODO: we only do this to catch a changed IPv4/IPv6 stack state.
        //       we can probably handle this more elegantly than rewriting torrc.
        NSInteger ipSetting = [[appDelegate.getSettings valueForKey:@"tor_ipv4v6"] integerValue];
        if (ipSetting == OB_IPV4V6_AUTO) {
            NSInteger ipv6_status = [Ipv6Tester ipv6_status];
            if ( ((ipv6_status == TOR_IPV6_CONN_ONLY) && (_connLastAutoIPStack != CONN_LAST_AUTO_IPV4V6_IPV6)) ||
                ((ipv6_status == TOR_IPV6_CONN_DUAL) && (_connLastAutoIPStack != CONN_LAST_AUTO_IPV4V6_DUAL)) ||
                ((ipv6_status == TOR_IPV6_CONN_FALSE) && (_connLastAutoIPStack != CONN_LAST_AUTO_IPV4V6_IPV4)) ) {
                // The IP stack changed; update our conn settings.
                [appDelegate updateTorrc];
                // Stash new state so we know if we change next time around..
                if (ipv6_status == TOR_IPV6_CONN_ONLY) {
                    _connLastAutoIPStack = CONN_LAST_AUTO_IPV4V6_IPV6;
                } else if (ipv6_status == TOR_IPV6_CONN_DUAL) {
                    _connLastAutoIPStack = CONN_LAST_AUTO_IPV4V6_DUAL;
                } else {
                    _connLastAutoIPStack = CONN_LAST_AUTO_IPV4V6_IPV4;
                }
            }
        }
        [self hupTor];
    }
}

- (void)appDidEnterBackground {
    [self disableTorCheckLoop];
}

- (void)appDidBecomeActive {
    nbrFailedAttempts = 0;
    
    if (![_mSocket isConnected]) {
        [_mSocket writeString:@"SIGNAL HUP\n" encoding:NSUTF8StringEncoding];
    }
#ifdef DEBUG
    NSLog(@"[Tor] Came back from background, trying to talk to Tor again" );
#endif
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate.logViewController logInfo:@"[Tor] Came back from background, trying to talk to Tor again"];

    _torCheckLoopTimer = [NSTimer scheduledTimerWithTimeInterval:0.25f
                                                          target:self
                                                        selector:@selector(activateTorCheckLoop)
                                                        userInfo:nil
                                                         repeats:NO];
}

#pragma mark -
#pragma mark Tor control port

- (void)activateTorCheckLoop {
#ifdef DEBUG
    NSLog(@"[Tor] Checking Tor Control Port" );
#endif
    
    _controllerIsAuthenticated = NO;
    
    [ULINetSocket ignoreBrokenPipes];
    // Create a new ULINetSocket connected to the host. Since ULINetSocket is asynchronous, the socket is not
    // connected to the host until the delegate method is called.
    _mSocket = [ULINetSocket netsocketConnectedToHost:@"127.0.0.1" port:_torControlPort];
    
    // Schedule the ULINetSocket on the current runloop
    [_mSocket scheduleOnCurrentRunLoop];
    
    // Set the ULINetSocket's delegate to ourself
    [_mSocket setDelegate:self];
}

- (void)disableTorCheckLoop {
    // When in background, don't poll the Tor control port.
    [ULINetSocket ignoreBrokenPipes];
    [_mSocket close];
    _mSocket = nil;
    
    [_torCheckLoopTimer invalidate];
}

- (void)checkTor {
    if (!didFirstConnect) {
        // We haven't loaded a page yet, so we are checking against bootstrap first.
        [_mSocket writeString:@"getinfo status/bootstrap-phase\n" encoding:NSUTF8StringEncoding];
    }
    else {
        // This is a "heartbeat" check, so we are checking our circuits.
        [_mSocket writeString:@"getinfo orconn-status\n" encoding:NSUTF8StringEncoding];
        if (_torStatusTimeoutTimer != nil) {
            [_torStatusTimeoutTimer invalidate];
        }
        _torStatusTimeoutTimer = [NSTimer scheduledTimerWithTimeInterval:STATUS_CHECK_TIMEOUT
                                                                  target:self
                                                                selector:@selector(checkTorStatusTimeout)
                                                                userInfo:nil
                                                                 repeats:NO];
    }
}

- (void)checkTorStatusTimeout {
    // Our orconn-status check didn't return before the alotted timeout.
    // (We're basically giving it STATUS_CHECK_TIMEOUT seconds -- default 1 sec
    // -- since this is a LOCAL port and LOCAL instance of tor, it should be
    // near instantaneous.)
    //
    // Fail: Restart Tor? (Maybe HUP?)
    NSLog(@"[Tor] checkTor timed out, attempting to restart tor");
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate.logViewController logInfo:@"[Tor] checkTor timed out, attempting to restart tor"];
    //[self startTor];
    [self hupTor];
}

- (void) disableNetwork {
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [[appDelegate tabsViewController] stopLoading];
    [[appDelegate tabsViewController] setTabsNeedForceRefresh:YES];
    [_mSocket writeString:@"setconf disablenetwork=1\n" encoding:NSUTF8StringEncoding];
    [appDelegate.logViewController logInfo:@"[Tor] DisableNetwork is set: Tor will not make or accept non-control network connections, shutting down all existing connections"];
}

- (void) enableNetwork {
    [_mSocket writeString:@"setconf disablenetwork=0\n" encoding:NSUTF8StringEncoding];
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [[appDelegate tabsViewController] refreshCurrentTab];
    [appDelegate.logViewController logInfo:@"[Tor] DisableNetwork is unset: Tor now accepts network connections"];
    [appDelegate.logViewController logInfo:@"[Tor] Received reload signal (hup): reloading config and resetting internal state"];
}

- (void)netsocketConnected:(ULINetSocket*)inNetSocket {
    /* Authenticate on first control port connect */
#ifdef DEBUG
    NSLog(@"[Tor] Control Port Connected" );
#endif
    //NSData *torCookie = [_torThread readTorCookie];
    //NSString *authMsg = [NSString stringWithFormat:@"authenticate %@\n",
    //                     [torCookie hexadecimalString]];
    NSString *authMsg = [NSString stringWithFormat:@"authenticate \"onionbrowser\"\n"];
    [_mSocket writeString:authMsg encoding:NSUTF8StringEncoding];
    
    _controllerIsAuthenticated = NO;
}

- (void)netsocketDisconnected:(ULINetSocket*)inNetSocket {
#ifdef DEBUG
    NSLog(@"[Tor] Control Port Disconnected" );
#endif
    
    if (nbrFailedAttempts <= MAX_FAILED_ATTEMPTS) {
        // Attempt to reconnect the netsocket
        [self disableTorCheckLoop];
        [self performSelector:@selector(activateTorCheckLoop) withObject:nil afterDelay:CONTROL_PORT_RECONNECT_WAIT];
        [self activateTorCheckLoop];
        nbrFailedAttempts += didFirstConnect; // If didn't first connect, will remain at 0
    }
}

- (void)netsocket:(ULINetSocket*)inNetSocket dataAvailable:(unsigned)inAmount {
    NSString *msgIn = [_mSocket readString:NSUTF8StringEncoding];
    
    if (!_controllerIsAuthenticated) {
        // Response to AUTHENTICATE
        if ([msgIn hasPrefix:@"250"]) {
#ifdef DEBUG
            NSLog(@"[Tor] Control Port Authenticated Successfully");
#endif
            
            AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
            [appDelegate.logViewController logInfo:@"[Tor] Control Port Authenticated Successfully"];
            _controllerIsAuthenticated = YES;
            
            [_mSocket writeString:@"getinfo status/bootstrap-phase\n" encoding:NSUTF8StringEncoding];
            _torCheckLoopTimer = [NSTimer scheduledTimerWithTimeInterval:0.15f
                                                                  target:self
                                                                selector:@selector(checkTor)
                                                                userInfo:nil
                                                                 repeats:NO];
        }
        else {
#ifdef DEBUG
            NSLog(@"[Tor] Control Port: Got unknown post-authenticate message %@", msgIn);
#endif
            // Could not authenticate with control port. This is the worst thing
            // that can happen on app init and should fail badly so that the
            // app does not just hang there.
            if (didFirstConnect) {
                // If we've already performed initial connect, wait a couple
                // seconds and try to HUP tor.
                if (_torCheckLoopTimer != nil) {
                    [_torCheckLoopTimer invalidate];
                }
                if (_torStatusTimeoutTimer != nil) {
                    [_torStatusTimeoutTimer invalidate];
                }
                _torCheckLoopTimer = [NSTimer scheduledTimerWithTimeInterval:2.5f
                                                                      target:self
                                                                    selector:@selector(hupTor)
                                                                    userInfo:nil
                                                                     repeats:NO];
            } else {
                // Otherwise, crash because we don't know the app's current state
                // (since it hasn't totally initialized yet).
                exit(0);
            }
        }
    } else if ([msgIn rangeOfString:@"-status/bootstrap-phase="].location != NSNotFound) {
        // Response to "getinfo status/bootstrap-phase"
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        
        if ([msgIn rangeOfString:@"BOOTSTRAP PROGRESS=100"].location != NSNotFound) {
            _connectionStatus = CONN_STATUS_CONNECTED;
        }
        
        TabsViewController *tvc = appDelegate.tabsViewController;
        if (!didFirstConnect) {
            if ([msgIn rangeOfString:@"BOOTSTRAP PROGRESS=100"].location != NSNotFound) {
                // This is our first go-around (haven't loaded page into webView yet)
                // but we are now at 100%, so go ahead.
                didFirstConnect = YES;
                
                [tvc renderTorStatus:msgIn];
                
                JFMinimalNotification *minimalNotification = [JFMinimalNotification notificationWithStyle:JFMinimalNotificationStyleDefault title:NSLocalizedString(@"Initializing Tor circuit…", nil) subTitle:NSLocalizedString(@"First page load may be slow to start.", nil) dismissalDelay:4.0];
                minimalNotification.layer.zPosition = MAXFLOAT;
                [tvc.view addSubview:minimalNotification];
                [minimalNotification show];
                
                // See "checkTor call in middle of app" a little bit below.
                _torCheckLoopTimer = [NSTimer scheduledTimerWithTimeInterval:5.0f
                                                                      target:self
                                                                    selector:@selector(checkTor)
                                                                    userInfo:nil
                                                                     repeats:NO];
            } else {
                // Haven't done initial load yet and still waiting on bootstrap, so
                // render status.
                [tvc renderTorStatus:msgIn];
                _torCheckLoopTimer = [NSTimer scheduledTimerWithTimeInterval:TOR_STATUS_WAIT
                                                                      target:self
                                                                    selector:@selector(checkTor)
                                                                    userInfo:nil
                                                                     repeats:NO];
            }
        }
    } else if ([msgIn rangeOfString:@"orconn-status="].location != NSNotFound) {
        [_torStatusTimeoutTimer invalidate];
        // Response to "getinfo orconn-status"
        // This is a response to a "checkTor" call in the middle of our app.
        if ([msgIn rangeOfString:@"250 OK"].location == NSNotFound) {
            // Bad stuff! Should HUP since this means we can still talk to Tor, but Tor is having issues with it's onion routing connections.
            NSLog(@"[Tor] Control Port: orconn-status: NOT OK\n    %@",
                  [msgIn
                   stringByReplacingOccurrencesOfString:@"\n"
                   withString:@"\n    "]
                  );
            
            AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
            [appDelegate.logViewController logInfo:[NSString stringWithFormat:@"[Tor] Control Port: orconn-status: NOT OK\n    %@", [msgIn stringByReplacingOccurrencesOfString:@"\n" withString:@"\n    "]]];

            [self hupTor];
        } else {
#ifdef DEBUG
            NSLog(@"[Tor] Control Port: orconn-status: OK");
#endif
            _torCheckLoopTimer = [NSTimer scheduledTimerWithTimeInterval:5.0f
                                                                  target:self
                                                                selector:@selector(checkTor)
                                                                userInfo:nil
                                                                 repeats:NO];
        }
    
    } else if ([msgIn rangeOfString:@"circuit-status="].location != NSNotFound) {
        NSMutableArray *guards = [[msgIn componentsSeparatedByString: @"\r\n"] mutableCopy];
        
#ifdef DEBUG
        NSLog(@"circuit-status guards: %@", guards);
#endif
        
        if ([guards count] > 1) {
            // If the value is correct, the first object should be "250+entry-guards="
            // The next ones should be "$<ID>~<NAME> <STATUS>"
            [guards removeObjectAtIndex:0];
            
            // Keep, for each circuit, its ID and order them
            NSMutableArray *circuitOrder = [[NSMutableArray alloc] init];
            
            for (__strong NSString *circuitInfo in guards) {
                NSMutableArray<TorNode *> *currentNodes = [[NSMutableArray alloc] init];
                
                // Format should be "<ID> <STATUS> <NODES> BUILD_FLAGS=<FLAGS> PURPOSE=<PURPOSE> TIME_CREATED=<ISO8601_TIME>"
                NSArray *info = [circuitInfo componentsSeparatedByString:@" "]; // Infos are separated by spaces
                
                // If there isn't enough info, this isn't a circuit
                if ([info count] < 6)
                    continue;
                
                NSNumber *circuitID = [NSNumber numberWithInt:[[info objectAtIndex:0] intValue]];
                
                // Find the proper index for this node for the array to be ordered by ID
                int index = 0;
                for (int i = 0; i < [circuitOrder count]; i++) {
                    if ([[circuitOrder objectAtIndex:i] objectAtIndex:0] > circuitID)
                        break;
                    index++;
                }
                
                // Find the build flags and convert them to a list
                NSString *flags = [[info objectAtIndex:3] substringFromIndex:@"BUILD_FLAGS=".length];
                NSArray *buildFlags = [flags componentsSeparatedByString:@","]; // Flags are separated by comas
                
                // Find the circuit's purpose
                NSString *purpose = [[info objectAtIndex:4] substringFromIndex:@"PURPOSE=".length];
                
                // Find the created time and convert it to a date
                NSString *timeCreated = [[info objectAtIndex:5] substringFromIndex:@"TIME_CREATED=".length];
                NSDate *dateCreated = [self parseISO8601Time:timeCreated];
                
                TorCircuit *circuit = [[TorCircuit alloc] init];
                [circuit setID:circuitID];
                [circuit setBuildFlags:buildFlags];
                [circuit setPurpose:purpose];
                [circuit setTimeCreated:dateCreated];
                [circuitOrder insertObject:[NSArray arrayWithObjects:circuitID, circuit, nil] atIndex:index];
                
                NSString *nodes = [info objectAtIndex:2];
                NSRange r1 = [nodes rangeOfString:@"$"];
                NSRange r2 = [nodes rangeOfString:@"~"];
                NSRange idRange = NSMakeRange(r1.location + r1.length, r2.location - r1.location - r1.length);

                while (r1.location != NSNotFound && r2.location != NSNotFound && idRange.location != NSNotFound) {
                    NSString *nodeID = [nodes substringWithRange:idRange];
                    
                    // Add node to the array
                    TorNode *node = [[TorNode alloc] init];
                    [node setID:nodeID];
                    [currentNodes addObject:node];
                    
                    // Get IP for the current exit
                    [_mSocket writeString:[NSString stringWithFormat:@"getinfo ns/id/%@\n", nodeID] encoding:NSUTF8StringEncoding];
                    
                    // Move on to next node (if it exists)
                    nodes = [nodes substringFromIndex:r2.location + 1];
                    r1 = [nodes rangeOfString:@"$"];
                    r2 = [nodes rangeOfString:@"~"];
                    idRange = NSMakeRange(r1.location + r1.length, r2.location - r1.location - r1.length);
                }
                
                [circuit setNodes:currentNodes];
            }
            
            // Add all the circuits to the array in the right order
            for (NSArray *circuitInfo in circuitOrder) {
                [_currentCircuits addObject:[circuitInfo objectAtIndex:1]];
            }
        }
    } else if ([msgIn rangeOfString:@"ns/id/"].location != NSNotFound) {
        // Multiple results can be received at the same time
        NSArray *requests = [msgIn componentsSeparatedByString:@"250+ns/id/"];
        
        for (NSString *msg in requests) {
            NSMutableArray *infoArray = [[msg componentsSeparatedByString: @"\r\n"] mutableCopy];
            
            if ([infoArray count] > 1) {
                /* Extract the node's ID */
                // Format should be "<ID>="
                NSString *tmp = [infoArray objectAtIndex:0];
                NSString *nodeID = [tmp substringToIndex:[tmp length] - 1]; // Get rid of the "="
                
                /* Find the matching nodes */
                NSMutableArray<TorNode *> *correspondingNodes = [[NSMutableArray alloc] init];
                for (TorCircuit *circuit in self.currentCircuits) {
                    for (TorNode *node in circuit.nodes) {
                        if ([node.ID isEqualToString:nodeID]) {
                            [correspondingNodes addObject:node];
                            break;
                        }
                    }
                }
                
                if ([correspondingNodes count] == 0)
                    return; // We don't care about this node since it's not in self.currentNodes
                
                /* Extract the node's name and IP */
                // Format should be "r <NAME> C3ZsrjOVPuRpCX2dprynFoY/jrQ awageVh+KgvJYAgPcG5kruCcJPo <TIME> <IP> 9001 9030"
                // e.g. "Iroha C3ZsrjOVPuRpCX2dprynFoY/jrQ awageVh+KgvJYAgPcG5kruCcJPo 2016-05-22 05:04:19 185.21.217.32 9001 9030"
                tmp = [[infoArray objectAtIndex:1] substringFromIndex:2]; // Get rid of the "r "
                NSString *nodeName = [tmp substringToIndex:[tmp rangeOfString:@" "].location];
                
                NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)" options:NSRegularExpressionCaseInsensitive error:nil];
                NSArray *matches = [regex matchesInString:tmp options:0 range:NSMakeRange(0, [tmp length])];
                NSString *nodeIP = [tmp substringWithRange:[[matches objectAtIndex:0] rangeAtIndex:0]];
                
                for (TorNode *node in correspondingNodes) {
                    [node setName:nodeName];
                    [node setIP:nodeIP];

                }
                
                // Find the node's country
                [_mSocket writeString:[NSString stringWithFormat:@"getinfo ip-to-country/%@\n", nodeIP] encoding:NSUTF8StringEncoding];
                
                /* Extract the node's version */
                if ([infoArray count] <= 2)
                    return;
                // Format should be "s <VERSION_INFO>"
                tmp = [[infoArray objectAtIndex:2] substringFromIndex:2]; // Get rid of the "w Bandwidth="
                for (TorNode *node in correspondingNodes) {
                    [node setVersion:tmp];
                }

                /* Extract the node's bandwidth */
                if ([infoArray count] <= 3)
                    return;
                // Format should be "w Bandwidth=<BANDWIDTH>"
                tmp = [[infoArray objectAtIndex:3] substringFromIndex:12]; // Get rid of the "w Bandwidth="
                for (TorNode *node in correspondingNodes) {
                    [node setBandwidth:[NSNumber numberWithInt:[tmp intValue]]];
                }
            }
        }
    } else if ([msgIn rangeOfString:@"ip-to-country/"].location != NSNotFound) {
        // Multiple results can be received at the same time
        NSArray *requests = [msgIn componentsSeparatedByString:@"250-ip-to-country/"];

        for (NSString *msg in requests) {
            NSMutableArray *infoArray = [[msg componentsSeparatedByString: @"\r\n"] mutableCopy];
            
            if ([infoArray count] > 1) {
                /* Extract the node's IP */
                // Format should be "<IP>=<COUNTRY>"
                NSString *tmp = [infoArray objectAtIndex:0];
                NSString *nodeIP = [tmp substringToIndex:[tmp rangeOfString:@"="].location];
                
                /* Find the matching nodes */
                NSMutableArray<TorNode *> *correspondingNodes = [[NSMutableArray alloc] init];
                for (TorCircuit *circuit in self.currentCircuits) {
                    for (TorNode *node in circuit.nodes) {
                        if ([node.IP isEqualToString:nodeIP]) {
                            [correspondingNodes addObject:node];
                            break;
                        }
                    }
                }
                
                if ([correspondingNodes count] == 0)
                    return; // We don't care about this node since it's not in self.currentNodes
                
                /* Extract the node's country */
                // Format should be "<IP>=<COUNTRY>"
                for (TorNode *node in correspondingNodes) {
                    [node setCountry:[tmp substringFromIndex:[tmp rangeOfString:@"="].location + 1]];
                }
            }
        }
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        NSString *logString = @"[Tor] Found all current circuit's info:";
        
        for (TorNode *node in [self.currentCircuits objectAtIndex:0].nodes) {
            logString = [logString stringByAppendingString:[NSString stringWithFormat:@"\n• %@: %@ (%@) - ID=%@, Bandwidth=%@, v=%@", node.name, node.IP, node.country, node.ID, node.bandwidth, node.version]];
        }
        
        [appDelegate.logViewController logInfo:logString];
    } else {
#ifdef DEBUG
        NSLog(@"msgIn: %@", msgIn);
#endif
    }
}

- (void)netsocketDataSent:(ULINetSocket*)inNetSocket { }


#pragma mark - Helper methods

- (NSDate *)parseISO8601Time:(NSString *)date {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSSSS"];
    NSLocale *posix = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    [formatter setLocale:posix];
    
    return [formatter dateFromString:date];
}


@end
