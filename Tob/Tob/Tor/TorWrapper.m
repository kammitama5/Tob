// Copyright © 2012-2016 Mike Tigas
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "TorWrapper.h"
#import "AppDelegate.h"
#import "Ipv6Tester.h"

@implementation TorWrapper
@synthesize tor;

//-(NSData *)readTorCookie {
//    /* We have the CookieAuthentication ControlPort method set up, so Tor
//     * will create a "control_auth_cookie" in the data dir. The contents of this
//     * file is the data that AppDelegate will use to communicate back to Tor. */
//    NSString *tmpDir = NSTemporaryDirectory();
//    NSString *control_auth_cookie = [tmpDir stringByAppendingPathComponent:@"control_auth_cookie"];
//
//    NSData *cookie = [[NSData alloc] initWithContentsOfFile:control_auth_cookie];
//    return cookie;
//}

-(void)start {
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    NSString *base_torrc = [[[appDelegate applicationDocumentsDirectory] URLByAppendingPathComponent:@"torrc"] relativePath];
    NSString *geoip = [[NSBundle mainBundle] pathForResource:@"geoip" ofType:nil];
    NSString *geoip6 = [[NSBundle mainBundle] pathForResource:@"geoip6" ofType:nil];
    
    NSString *controlPortStr = [NSString stringWithFormat:@"%ld", (unsigned long)appDelegate.tor.torControlPort];
    NSString *socksPortStr = [NSString stringWithFormat:@"%ld", (unsigned long)appDelegate.tor.torSocksPort];
    
    //NSLog(@"%@ / %@", controlPortStr, socksPortStr);
    
    /**************/
    
    TORConfiguration *conf = [[TORConfiguration alloc] init];
    conf.cookieAuthentication = [NSNumber numberWithBool:YES];
    //conf.dataDirectory = [NSURL fileURLWithPath:NSTemporaryDirectory()];
    conf.dataDirectory = [[[appDelegate applicationLibraryDirectory] URLByAppendingPathComponent:@"Caches" isDirectory:YES] URLByAppendingPathComponent:@"tor" isDirectory:YES];
    
    
    /*
     configuration.arguments = [
     "--ignore-missing-torrc",
     "--clientonly", "1",
     "--socksport", "39050",
     "--controlport", "127.0.0.1:39060",
     //"--log", "notice stdout",
     "--log", "notice file /dev/null",
     "--clientuseipv4", "1",
     "--clientuseipv6", "1",
     "--ClientPreferIPv6ORPort", "auto",
     "--ClientPreferIPv6DirPort", "auto",
     "--ClientTransportPlugin", "obfs4 socks5 127.0.0.1:47351",
     "--ClientTransportPlugin", "meek_lite socks5 127.0.0.1:47352",
     ]
     */
    
    NSMutableArray *arguments = [[NSMutableArray alloc] initWithObjects:@"-f", base_torrc,
                            @"--clientonly", @"1",
                            @"--socksport", socksPortStr,
                            @"--controlport", controlPortStr,
                            @"--log", @"notice file /dev/null",
                            @"--geoipfile", geoip,
                            @"--geoipv6file", geoip6,
                            @"--ClientTransportPlugin", @"obfs4 socks5 127.0.0.1:47351",
                            @"--ClientTransportPlugin", @"meek_lite socks5 127.0.0.1:47352",
                            nil];
    
    NSMutableDictionary *settings = appDelegate.getSettings;
    NSInteger ipSetting = [[settings valueForKey:@"tor_ipv4v6"] integerValue];
    NSInteger ipv6_status = [Ipv6Tester ipv6_status]; // Always call this to make sure the IP info is logged
    if (ipSetting == OB_IPV4V6_AUTO) {
        if (ipv6_status == TOR_IPV6_CONN_ONLY) {
            [arguments addObjectsFromArray:@[@"--ClientPreferIPv6ORPort", @"1",
                                             @"--ClientPreferIPv6DirPort", @"1",
                                             @"--ClientUseIPv4", @"0",
                                             @"--ClientUseIPv6", @"1"]];
        } else if (ipv6_status == TOR_IPV6_CONN_DUAL) {
            [arguments addObjectsFromArray:@[@"--ClientPreferIPv6ORPort", @"auto",
                                             @"--ClientPreferIPv6DirPort", @"auto",
                                             @"--ClientUseIPv4", @"1",
                                             @"--ClientUseIPv6", @"1"]];
        } else {
            [arguments addObjectsFromArray:@[@"--ClientPreferIPv6ORPort", @"0",
                                             @"--ClientPreferIPv6DirPort", @"0",
                                             @"--ClientUseIPv4", @"1",
                                             @"--ClientUseIPv6", @"0"]];
        }
    } else if (ipSetting == OB_IPV4V6_V6ONLY) {
        [arguments addObjectsFromArray:@[@"--ClientPreferIPv6ORPort", @"1",
                                         @"--ClientPreferIPv6DirPort", @"1",
                                         @"--ClientUseIPv4", @"0",
                                         @"--ClientUseIPv6", @"1"]];
    } else {
        [arguments addObjectsFromArray:@[@"--ClientPreferIPv6ORPort", @"auto",
                                         @"--ClientPreferIPv6DirPort", @"auto"]];
    }
    
#ifdef DEBUG
    NSLog(@"Starting Tor with arguments %@", arguments);
#endif
    
    conf.arguments = arguments;
    
    tor = [[TORThread alloc] initWithConfiguration:conf];
    [tor start];
    
}

@end
