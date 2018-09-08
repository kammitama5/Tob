//
//  SettingsTableViewController.m
//  OnionBrowser
//
//  Created by Mike Tigas on 5/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SettingsTableViewController.h"
#import "AppDelegate.h"
#import "Bridge.h"
#import "BridgesTableViewController.h"
#import "BookmarkTableViewController.h"
#import "BookmarkEditViewController.h"
#import "Bookmark.h"
#import "Ipv6Tester.h"
#import "URLBlocker.h"

@interface SettingsTableViewController ()

@end

@implementation SettingsTableViewController
@synthesize backButton;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    backButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done", nil) style:UIBarButtonItemStyleDone target:self action:@selector(goBack)];
    self.navigationItem.rightBarButtonItem = backButton;
    self.navigationItem.title = NSLocalizedString(@"Settings", nil);
    
    if ([self.tableView respondsToSelector:@selector(setCellLayoutMarginsFollowReadableWidth:)]) {
        self.tableView.cellLayoutMarginsFollowReadableWidth = NO;
    }
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
    self.tabsNeedsRefresh = NO;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if (self.tabsNeedsRefresh) {
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        [[appDelegate tabsViewController] setTabsNeedForceRefresh:YES];
        self.tabsNeedsRefresh = NO;
    }
}

- (void)goBack {
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 5;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0)
        return 7; // Bookmarks * 2, homepage, search engine, reopen closed tabs, night mode, hide screen in background.
    else if (section == 1)
        return 3; // Cookies, UA spoofing, DNT
    else if (section == 2)
        return 5; // Active content, javascript, TLS/SSL, IPv5/IPv4, bridges
    else if (section == 3)
        return 3; // Enable content blocker, whitelist, ruleset
    else if (section == 4)
        return 3; // App store, report a bug, credits
    else
        return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0)
        return NSLocalizedString(@"User Interface", nil);
    else if (section == 1)
        return NSLocalizedString(@"Privacy", nil);
    else if (section == 2)
        return NSLocalizedString(@"Security", nil);
    else if (section == 3)
        return NSLocalizedString(@"Content blocker", nil);
    else if (section == 4)
        return NSLocalizedString(@"Miscellaneous", nil);
    else
        return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *CellIdentifier = @"Cell";
    
    if ((indexPath.section == 0 && (indexPath.row == 2 || indexPath.row == 3)) || (indexPath.section == 1 && (indexPath.row == 0 || indexPath.row == 1)) || (indexPath.section == 2 && (indexPath.row == 0 || indexPath.row == 2 || indexPath.row == 3)))
        CellIdentifier = @"Detail cell";
    else if ((indexPath.section == 0 && (indexPath.row == 4 || indexPath.row == 5 || indexPath.row == 6)) || (indexPath.section == 1 && indexPath.row == 2) || (indexPath.section == 2 && indexPath.row == 1) || (indexPath.section == 3 && indexPath.row == 0))
        CellIdentifier = @"Switch cell";
    else if (indexPath.section == 2 && indexPath.row == 4)
        CellIdentifier = @"Subtitle cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        if ([CellIdentifier isEqual:@"Detail cell"])
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
        else if ([CellIdentifier isEqual:@"Subtitle cell"])
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        else
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    cell.userInteractionEnabled = YES;
    cell.textLabel.textColor = [UIColor blackColor];
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    cell.textLabel.minimumScaleFactor = 0.8;
    
    if (indexPath.section == 0) {
        // User Interface
        if (indexPath.row == 0) {
            cell.textLabel.text = NSLocalizedString(@"Bookmark current URL", nil);
            cell.textLabel.textAlignment = NSTextAlignmentCenter;
            cell.textLabel.textColor = self.view.tintColor;
            cell.accessoryType = UITableViewCellAccessoryNone;
        } else if (indexPath.row == 1) {
            cell.textLabel.text = NSLocalizedString(@"Edit bookmarks", nil);
            cell.textLabel.textAlignment = NSTextAlignmentCenter;
            cell.textLabel.textColor = self.view.tintColor;
            cell.accessoryType = UITableViewCellAccessoryNone;
        } if (indexPath.row == 2) {
            AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
            NSMutableDictionary *settings = appDelegate.getSettings;
            cell.textLabel.text = NSLocalizedString(@"Homepage", nil);
            cell.detailTextLabel.text = [settings objectForKey:@"homepage"];
            cell.accessoryType = UITableViewCellAccessoryNone;
        } else if (indexPath.row == 3) {
            cell.textLabel.text = NSLocalizedString(@"Search engine", nil);
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
            NSMutableDictionary *settings = appDelegate.getSettings;
            cell.detailTextLabel.text = [settings valueForKey:@"search-engine"];
        } else if (indexPath.row == 4) {
            AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
            NSMutableDictionary *settings = appDelegate.getSettings;
            BOOL saveAppState = [[settings valueForKey:@"save-app-state"] boolValue];
            
            cell.textLabel.text = NSLocalizedString(@"Reopen tabs", nil);
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            UISwitch *switchView = [[UISwitch alloc] initWithFrame:CGRectZero];
            cell.accessoryView = switchView;
            [switchView setOn:saveAppState animated:NO];
            [switchView addTarget:self action:@selector(appStateSwitchChanged:) forControlEvents:UIControlEventValueChanged];
        } else if (indexPath.row == 5) {
            AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
            NSMutableDictionary *settings = appDelegate.getSettings;
            BOOL nightMode = [[settings valueForKey:@"night-mode"] boolValue];
            
            cell.textLabel.text = NSLocalizedString(@"Night mode", nil);
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            UISwitch *switchView = [[UISwitch alloc] initWithFrame:CGRectZero];
            cell.accessoryView = switchView;
            [switchView setOn:nightMode animated:NO];
            [switchView addTarget:self action:@selector(nightSwitchChanged:) forControlEvents:UIControlEventValueChanged];
        } else if (indexPath.row == 6) {
            AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
            NSMutableDictionary *settings = appDelegate.getSettings;
            BOOL hideScreen = [[settings valueForKey:@"hide-screen"] boolValue];
            
            cell.textLabel.text = NSLocalizedString(@"Hide screen in background", nil);
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            UISwitch *switchView = [[UISwitch alloc] initWithFrame:CGRectZero];
            cell.accessoryView = switchView;
            [switchView setOn:hideScreen animated:NO];
            [switchView addTarget:self action:@selector(hideScreenSwitchChanged:) forControlEvents:UIControlEventValueChanged];
        }
    } else if (indexPath.section == 1) {
        // Privacy
        if (indexPath.row == 0) {
            cell.textLabel.text = NSLocalizedString(@"Cookies", nil);
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

            NSHTTPCookieAcceptPolicy currentCookieStatus = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookieAcceptPolicy];
            if (currentCookieStatus == NSHTTPCookieAcceptPolicyAlways)
                cell.detailTextLabel.text = NSLocalizedString(@"Allow all", nil);
            else if (currentCookieStatus == NSHTTPCookieAcceptPolicyOnlyFromMainDocumentDomain)
                cell.detailTextLabel.text = NSLocalizedString(@"Block third-party", nil);
            else
                cell.detailTextLabel.text = NSLocalizedString(@"Block all", nil);
            
        } else if (indexPath.row == 1) {
            cell.textLabel.text = NSLocalizedString(@"User-Agent", nil);
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            
            AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
            NSMutableDictionary *settings = appDelegate.getSettings;
            NSInteger spoofUserAgent = [[settings valueForKey:@"uaspoof"] integerValue];
            
            if (spoofUserAgent == UA_SPOOF_NO)
                cell.detailTextLabel.text = NSLocalizedString(@"Standard", nil);
            else if (spoofUserAgent == UA_SPOOF_IPHONE)
                cell.detailTextLabel.text = NSLocalizedString(@"iPhone", nil);
            else if (spoofUserAgent == UA_SPOOF_IPAD)
                cell.detailTextLabel.text = NSLocalizedString(@"iPad", nil);
            else if (spoofUserAgent == UA_SPOOF_WIN7_TORBROWSER)
                cell.detailTextLabel.text = NSLocalizedString(@"Windows 7", nil);
            else if (spoofUserAgent == UA_SPOOF_SAFARI_MAC)
                cell.detailTextLabel.text = NSLocalizedString(@"Mac OS X", nil);
            else
                cell.detailTextLabel.text = @"";
            
        } else if (indexPath.row == 2) {
            AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
            NSMutableDictionary *settings = appDelegate.getSettings;
            NSInteger dntHeader = [[settings valueForKey:@"dnt"] integerValue];
            
            cell.textLabel.text = NSLocalizedString(@"Do-not-track", nil);
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            UISwitch *switchView = [[UISwitch alloc] initWithFrame:CGRectZero];
            cell.accessoryView = switchView;
            [switchView setOn:dntHeader == DNT_HEADER_NOTRACK animated:NO];
            [switchView addTarget:self action:@selector(dntSwitchChanged:) forControlEvents:UIControlEventValueChanged];
        }
    } else if (indexPath.section == 2) {
        // Security
        if (indexPath.row == 0) {
            cell.textLabel.text = NSLocalizedString(@"Active content", nil);
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            
            AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
            NSMutableDictionary *settings = appDelegate.getSettings;
            NSInteger csp_setting = [[settings valueForKey:@"javascript"] integerValue];
            
            if (csp_setting == CONTENTPOLICY_BLOCK_CONNECT)
                cell.detailTextLabel.text = NSLocalizedString(@"Block Ajax", nil);
            else if (csp_setting == CONTENTPOLICY_STRICT)
                cell.detailTextLabel.text = NSLocalizedString(@"Block all", nil);
            else if (csp_setting == CONTENTPOLICY_PERMISSIVE)
                cell.detailTextLabel.text = NSLocalizedString(@"Allow all", nil);
            else
                cell.detailTextLabel.text = @"";
        } else if (indexPath.row == 1) {
            AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
            NSMutableDictionary *settings = appDelegate.getSettings;
            NSInteger js_setting = [[settings valueForKey:@"javascript-toggle"] integerValue];
            
            cell.textLabel.text = NSLocalizedString(@"Disable javascript", nil);
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            UISwitch *switchView = [[UISwitch alloc] initWithFrame:CGRectZero];
            cell.accessoryView = switchView;
            [switchView setOn:js_setting == JS_BLOCKED animated:NO];
            [switchView addTarget:self action:@selector(jsSwitchChanged:) forControlEvents:UIControlEventValueChanged];
            
            NSInteger csp_setting = [[settings valueForKey:@"javascript"] integerValue];
            
            if (csp_setting == CONTENTPOLICY_STRICT) {
                [switchView setOn:YES animated:NO];
                cell.textLabel.textColor = [UIColor lightGrayColor];
                cell.userInteractionEnabled = NO;
                switchView.enabled = NO;
            } else {
                cell.userInteractionEnabled = YES;
                switchView.enabled = YES;
            }
        } else if (indexPath.row == 2) {
            cell.textLabel.text = NSLocalizedString(@"TLS/SSL", nil);
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            
            AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
            NSMutableDictionary *settings = appDelegate.getSettings;
            NSInteger dntHeader = [[settings valueForKey:@"tlsver"] integerValue];
            
            if (dntHeader == X_TLSVER_ANY)
                cell.detailTextLabel.text = NSLocalizedString(@"SSL v3", nil);
            else if (dntHeader == X_TLSVER_TLS1)
                cell.detailTextLabel.text = NSLocalizedString(@"TLS 1.0+", nil);
            else if (dntHeader == X_TLSVER_TLS1_2_ONLY)
                cell.detailTextLabel.text = NSLocalizedString(@"TLS 1.2", nil);
            else
                cell.detailTextLabel.text = @"";
        } else if (indexPath.row == 3) {
            cell.textLabel.text = NSLocalizedString(@"IPv4/IPv6", nil);
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            
            AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
            NSMutableDictionary *settings = appDelegate.getSettings;
            NSInteger ipv4v6Setting = [[settings valueForKey:@"tor_ipv4v6"] integerValue];
            
            if (ipv4v6Setting == OB_IPV4V6_AUTO)
                cell.detailTextLabel.text = NSLocalizedString(@"Auto", nil);
            else if (ipv4v6Setting == OB_IPV4V6_V6ONLY)
                cell.detailTextLabel.text = NSLocalizedString(@"IPv6", nil);
            else if (ipv4v6Setting == OB_IPV4V6_V4ONLY)
                cell.detailTextLabel.text = NSLocalizedString(@"IPv4", nil);
            else
                cell.detailTextLabel.text = @"";
        } else if (indexPath.row == 4) {
            AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
            
            NSFetchRequest *request = [[NSFetchRequest alloc] init];
            NSEntityDescription *entity = [NSEntityDescription entityForName:@"Bridge" inManagedObjectContext:appDelegate.managedObjectContext];
            [request setEntity:entity];
            
            NSError *error = nil;
            NSMutableArray *mutableFetchResults = [[appDelegate.managedObjectContext executeFetchRequest:request error:&error] mutableCopy];
            cell.textLabel.text = NSLocalizedString(@"Tor bridges", nil);
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            
            NSUInteger numBridges = [mutableFetchResults count];
            if (numBridges == 1)
                cell.detailTextLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%ld bridge configured", nil), (unsigned long)numBridges];
            else if (numBridges > 1)
                cell.detailTextLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%ld bridges configured", nil), (unsigned long)numBridges];
            else
                cell.detailTextLabel.text = nil;
        }
    } else if (indexPath.section == 3) {
        // Content blocker
        if (indexPath.row == 0) {
            AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
            NSMutableDictionary *settings = appDelegate.getSettings;
            BOOL blockContent = [[settings valueForKey:@"enable-content-blocker"] boolValue];
            
            cell.textLabel.text = NSLocalizedString(@"Block ads and trackers", nil);
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            UISwitch *switchView = [[UISwitch alloc] initWithFrame:CGRectZero];
            cell.accessoryView = switchView;
            [switchView setOn:blockContent animated:NO];
            [switchView addTarget:self action:@selector(enableContentBlockerSwitchChanged:) forControlEvents:UIControlEventValueChanged];
        } else if (indexPath.row == 1) {
            cell.textLabel.text = NSLocalizedString(@"Whitelist", nil);
            cell.textLabel.textAlignment = NSTextAlignmentLeft;
            cell.textLabel.textColor = [UIColor blackColor];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        } else if (indexPath.row == 2) {
            cell.textLabel.text = NSLocalizedString(@"Ruleset", nil);
            cell.textLabel.textAlignment = NSTextAlignmentLeft;
            cell.textLabel.textColor = [UIColor blackColor];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
    } else if (indexPath.section == 4) {
        // Miscellaneous
        if (indexPath.row == 0) {
            cell.textLabel.text = NSLocalizedString(@"Rate on the App Store", nil);
            cell.textLabel.textAlignment = NSTextAlignmentLeft;
            cell.textLabel.textColor = [UIColor blackColor];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        } else if (indexPath.row == 1) {
            cell.textLabel.text = NSLocalizedString(@"Report a bug", nil);
            cell.textLabel.textAlignment = NSTextAlignmentLeft;
            cell.textLabel.textColor = [UIColor blackColor];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        } else if (indexPath.row == 2) {
            cell.textLabel.text = NSLocalizedString(@"License", nil);
            cell.textLabel.textAlignment = NSTextAlignmentLeft;
            cell.textLabel.textColor = [UIColor blackColor];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
    }
    
    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            // Bookmark current
            AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
            NSManagedObjectContext *managedObjectContext = [appDelegate managedObjectContext];
            Bookmark *bookmark = (Bookmark *)[NSEntityDescription insertNewObjectForEntityForName:@"Bookmark" inManagedObjectContext:managedObjectContext];
            
            [bookmark setTitle:[[appDelegate.tabsViewController tabAtIndex:appDelegate.tabsViewController.currentIndex] title]];
            [bookmark setUrl:[[[[appDelegate.tabsViewController contentViews] objectAtIndex:appDelegate.tabsViewController.currentIndex] url] absoluteString]];
            
            BookmarkEditViewController *editController = [[BookmarkEditViewController alloc] initWithBookmark:bookmark isEditing:NO];
            [self presentViewController:editController animated:YES completion:nil];
        } else if (indexPath.row == 1) {
            // Edit bookmarks
            BookmarkTableViewController *bookmarksVC = [[BookmarkTableViewController alloc] initWithStyle:UITableViewStylePlain];
            UINavigationController *bookmarkNavController = [[UINavigationController alloc] initWithRootViewController:bookmarksVC];
            
            AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
            NSManagedObjectContext *context = [appDelegate managedObjectContext];
            bookmarksVC.managedObjectContext = context;
            
            [self presentViewController:bookmarkNavController animated:YES completion:nil];
        } else if (indexPath.row == 2) {
            // Homepage
            AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
            NSMutableDictionary *settings2 = appDelegate.getSettings;
            
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Homepage", nil) message:NSLocalizedString(@"Leave blank to use default Tob home page.", nil) preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil]];
            
            [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Save", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
                AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
                NSMutableDictionary *settings = appDelegate.getSettings;
                
                if ([[alert.textFields.firstObject text] length] == 0) {
                    [settings setValue:@"https://duckduckgo.com/html" forKey:@"homepage"]; // DEFAULT HOMEPAGE
                } else {
                    NSString *h = [alert.textFields.firstObject text];
                    if ( (![h hasPrefix:@"http:"]) && (![h hasPrefix:@"https:"]) && (![h hasPrefix:@"tob:"]) && (![h hasPrefix:@"about:"]) )
                        h = [NSString stringWithFormat:@"http://%@", h];
                    [settings setValue:h forKey:@"homepage"];
                }
                [appDelegate saveSettings:settings];
                [self.tableView reloadData];
            }]];
            
            [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
                textField.autocorrectionType = UITextAutocorrectionTypeNo;
                [textField setKeyboardType:UIKeyboardTypeURL];
                textField.text = [settings2 objectForKey:@"homepage"];
            }];
            
            [self presentViewController:alert animated:YES completion:NULL];
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
        } else if (indexPath.row == 3) {
            // Search engine
            SearchEngineTableViewController *searchViewController = [[SearchEngineTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
            [self.navigationController pushViewController:searchViewController animated:YES];
        }
    } else if (indexPath.section == 1) {
        if (indexPath.row == 0) {
            // Cookies
            CookiesTableViewController *cookiesViewController = [[CookiesTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
            [self.navigationController pushViewController:cookiesViewController animated:YES];
        } else if (indexPath.row == 1) {
            // User-Agent
            UserAgentTableViewController *uaViewController = [[UserAgentTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
            [self.navigationController pushViewController:uaViewController animated:YES];
        }
    } else if (indexPath.section == 2) {
        if (indexPath.row == 0) {
            // Active content
            ActiveContentTableViewController *acViewController = [[ActiveContentTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
            [self.navigationController pushViewController:acViewController animated:YES];
        } else if (indexPath.row == 2) {
            // TLS/SSL
            TLSTableViewController *tlsViewController = [[TLSTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
            [self.navigationController pushViewController:tlsViewController animated:YES];
        } else if (indexPath.row == 3) {
            // IPv4/IPv6
            IPTableViewController *IPVC = [[IPTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
            [self.navigationController pushViewController:IPVC animated:YES];
        } else if (indexPath.row == 4) {
            // Bridges
            BridgesTableViewController *bridgesVC = [[BridgesTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
            [self.navigationController pushViewController:bridgesVC animated:YES];
        }
    } else if (indexPath.section == 3) {
        if (indexPath.row == 1) {
            // Whitelist
            WhitelistTableViewController *whitelistViewController = [[WhitelistTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
            [self.navigationController pushViewController:whitelistViewController animated:YES];
        } else if (indexPath.row == 2) {
            // Ruleset
            RulesetTableViewController *rulesetViewController = [[RulesetTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
            [self.navigationController pushViewController:rulesetViewController animated:YES];
        }
    } else if (indexPath.section == 4) {
        if (indexPath.row == 0) {
            // Rate
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
            NSString *iTunesLink = @"https://itunes.apple.com/app/id1063151782";
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:iTunesLink]];
        } else if (indexPath.row == 1) {
            // Report bug
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Report a bug", nil) message:NSLocalizedString(@"This will open a webpage in another browser.", nil) preferredStyle:UIAlertControllerStyleAlert];
            
            [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil]];
            
            UIAlertAction *openAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Open", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
                NSString *githubLink = @"https://github.com/JRock007/Tob/issues/new";
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:githubLink]];
            }];
            [alert addAction:openAction];
            
            if ([alert respondsToSelector:@selector(setPreferredAction:)]) {
                // This isn't available on iOS 8.
                // On iOS 8, StyleCancel is in bold
                [alert setPreferredAction:openAction];
            }
            
            [self presentViewController:alert animated:YES completion:nil];
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
        } else if (indexPath.row == 2) {
            // License
            CreditsWebViewController *creditsViewController = [[CreditsWebViewController alloc] init];
            [self.navigationController pushViewController:creditsViewController animated:YES];
        }
    }
}


#pragma mark - UISwitches

- (void)dntSwitchChanged:(id)sender {
    UISwitch *switchControl = sender;
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSMutableDictionary *settings = appDelegate.getSettings;
    
    if (switchControl.on) {
        [settings setObject:[NSNumber numberWithInteger:DNT_HEADER_NOTRACK] forKey:@"dnt"];
        [appDelegate saveSettings:settings];
    } else {
        [settings setObject:[NSNumber numberWithInteger:DNT_HEADER_CANTRACK] forKey:@"dnt"];
        [appDelegate saveSettings:settings];
    }
}

- (void)appStateSwitchChanged:(id)sender {
    UISwitch *switchControl = sender;
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSMutableDictionary *settings = appDelegate.getSettings;
    [settings setObject:[NSNumber numberWithBool:switchControl.on] forKey:@"save-app-state"];
    [appDelegate saveSettings:settings];
}

- (void)nightSwitchChanged:(id)sender {
    UISwitch *switchControl = sender;
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSMutableDictionary *settings = appDelegate.getSettings;
    [settings setObject:[NSNumber numberWithBool:switchControl.on] forKey:@"night-mode"];
    [appDelegate saveSettings:settings];
}

- (void)hideScreenSwitchChanged:(id)sender {
    UISwitch *switchControl = sender;
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSMutableDictionary *settings = appDelegate.getSettings;
    [settings setObject:[NSNumber numberWithBool:switchControl.on] forKey:@"hide-screen"];
    [appDelegate saveSettings:settings];
}

- (void)jsSwitchChanged:(id)sender {
    UISwitch *switchControl = sender;
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSMutableDictionary *settings = appDelegate.getSettings;
    
    if (switchControl.on) {
        [settings setObject:[NSNumber numberWithInteger:JS_BLOCKED] forKey:@"javascript-toggle"];
        [appDelegate saveSettings:settings];
    } else {
        [settings setObject:[NSNumber numberWithInteger:JS_NO_PREFERENCE] forKey:@"javascript-toggle"];
        [appDelegate saveSettings:settings];
    }
    
    self.tabsNeedsRefresh = YES;
}

- (void)enableContentBlockerSwitchChanged:(id)sender {
    UISwitch *switchControl = sender;
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSMutableDictionary *settings = appDelegate.getSettings;
    [settings setObject:[NSNumber numberWithBool:switchControl.on] forKey:@"enable-content-blocker"];
    [appDelegate saveSettings:settings];
    
    self.tabsNeedsRefresh = YES;
}

@end





@interface SearchEngineTableViewController ()

@end

@implementation SearchEngineTableViewController {
    NSIndexPath *_currentIndexPath;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.title = NSLocalizedString(@"Search engine", nil);
    
    if ([self.tableView respondsToSelector:@selector(setCellLayoutMarginsFollowReadableWidth:)]) {
        self.tableView.cellLayoutMarginsFollowReadableWidth = NO;
    }
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0)
        return 2;
    else
        return 3;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0)
        return NSLocalizedString(@"Recommended search engines", nil);
    else if (section == 1)
        return NSLocalizedString(@"Other search engines", nil);
    
    return nil;
}
    
- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == 1)
    return NSLocalizedString(@"These search engines are known for trying to spy on their users and are therefore not recommended.", nil);
    
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithFrame:CGRectZero];
    }
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSMutableDictionary *settings = appDelegate.getSettings;
    NSString *searchEngine = [settings valueForKey:@"search-engine"];
    
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            cell.textLabel.text = @"DuckDuckGo";
            
            if ([searchEngine isEqualToString:cell.textLabel.text]) {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
                _currentIndexPath = indexPath;
            } else
                cell.accessoryType = UITableViewCellAccessoryNone;
        } else if (indexPath.row == 1) {
            cell.textLabel.text = @"Startpage";
            
            if ([searchEngine isEqualToString:cell.textLabel.text]) {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
                _currentIndexPath = indexPath;
            } else
                cell.accessoryType = UITableViewCellAccessoryNone;
        }
    } else {
        if (indexPath.row == 0) {
            cell.textLabel.text = @"Bing";
            
            if ([searchEngine isEqualToString:cell.textLabel.text]) {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
                _currentIndexPath = indexPath;
            } else
                cell.accessoryType = UITableViewCellAccessoryNone;
        } else if (indexPath.row == 1) {
            cell.textLabel.text = @"Yahoo";
            
            if ([searchEngine isEqualToString:cell.textLabel.text]) {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
                _currentIndexPath = indexPath;
            } else
                cell.accessoryType = UITableViewCellAccessoryNone;
        } else if (indexPath.row == 2) {
            cell.textLabel.text = @"Google";
            
            if ([searchEngine isEqualToString:cell.textLabel.text]) {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
                _currentIndexPath = indexPath;
            } else
                cell.accessoryType = UITableViewCellAccessoryNone;
        }
    }
    
    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSMutableDictionary *settings = appDelegate.getSettings;
    
    [tableView cellForRowAtIndexPath:_currentIndexPath].accessoryType = UITableViewCellAccessoryNone;
    [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryCheckmark;
    _currentIndexPath = indexPath;
    
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            [settings setObject:@"DuckDuckGo" forKey:@"search-engine"];
            [appDelegate saveSettings:settings];
        } else if (indexPath.row == 1) {
            [settings setObject:@"Startpage" forKey:@"search-engine"];
            [appDelegate saveSettings:settings];
        }
    } else {
        if (indexPath.row == 0) {
            [settings setObject:@"Bing" forKey:@"search-engine"];
            [appDelegate saveSettings:settings];
        } else if (indexPath.row == 1) {
            [settings setObject:@"Yahoo" forKey:@"search-engine"];
            [appDelegate saveSettings:settings];
        } else if (indexPath.row == 2) {
            [settings setObject:@"Google" forKey:@"search-engine"];
            [appDelegate saveSettings:settings];
            
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Search engine", nil) message:NSLocalizedString(@"Google is known to display captchas before each search to Tor users.\nSome users have experienced captcha loops. If this occurs, either change search engine or request a new identity in the Tor panel.", nil) preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleCancel handler:nil]];
            [self presentViewController:alert animated:YES completion:NULL];
        }
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end





@interface CookiesTableViewController ()

@end

@implementation CookiesTableViewController {
    int _currentRow;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.title = NSLocalizedString(@"Cookies", nil);
    
    if ([self.tableView respondsToSelector:@selector(setCellLayoutMarginsFollowReadableWidth:)]) {
        self.tableView.cellLayoutMarginsFollowReadableWidth = NO;
    }
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0)
        return 3;
    else
        return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == 0)
        return NSLocalizedString(@"Cookies allow the server to deliver a page tailored to a particular user, or the page itself can contain some script which is aware of the data in the cookie and so is able to carry information from one visit to the website (or related site) to the next.\nThird party cookies are stored by another website than the one you are visiting. Disabling those usually doesn't have any adverse effect on your browsing experience.\n\nDefault: block third-party.", nil);
    else
        return NSLocalizedString(@"Cookies and cache are automatically cleared when exiting the app.", nil);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithFrame:CGRectZero];
    }
    
    if (indexPath.section == 0) {
        cell.textLabel.textColor = [UIColor blackColor];
        cell.textLabel.textAlignment = NSTextAlignmentLeft;
        
        NSHTTPCookieAcceptPolicy currentCookieStatus = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookieAcceptPolicy];
        NSUInteger cookieStatusSection = 0;
        if (currentCookieStatus == NSHTTPCookieAcceptPolicyAlways)
            cookieStatusSection = 0;
        else if (currentCookieStatus == NSHTTPCookieAcceptPolicyOnlyFromMainDocumentDomain)
            cookieStatusSection = 1;
        else
            cookieStatusSection = 2;
        
        _currentRow = (int)cookieStatusSection;
        
        if (indexPath.row == cookieStatusSection)
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        else
            cell.accessoryType = UITableViewCellAccessoryNone;
        
        if (indexPath.row == 0)
            cell.textLabel.text = NSLocalizedString(@"Allow all", nil);
        else if (indexPath.row == 1)
            cell.textLabel.text = NSLocalizedString(@"Block third-party", nil);
        else
            cell.textLabel.text = NSLocalizedString(@"Block all", nil);
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.textLabel.textColor = self.view.tintColor;
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        
        cell.textLabel.text = NSLocalizedString(@"Clear cookies", nil);
    }
    
    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if (indexPath.section == 0) {
        NSMutableDictionary *settings = appDelegate.getSettings;
        
        [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:_currentRow inSection:indexPath.section]].accessoryType = UITableViewCellAccessoryNone;
        [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryCheckmark;
        _currentRow = (int)indexPath.row;
        
        if (indexPath.row == 0) {
            [settings setObject:[NSNumber numberWithInteger:COOKIES_ALLOW_ALL] forKey:@"cookies"];
            [appDelegate saveSettings:settings];
            [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookieAcceptPolicy:NSHTTPCookieAcceptPolicyAlways];
        } else if (indexPath.row == 1) {
            [settings setObject:[NSNumber numberWithInteger:COOKIES_BLOCK_THIRDPARTY] forKey:@"cookies"];
            [appDelegate saveSettings:settings];
            [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookieAcceptPolicy:NSHTTPCookieAcceptPolicyOnlyFromMainDocumentDomain];
        } else if (indexPath.row == 2) {
            [settings setObject:[NSNumber numberWithInteger:COOKIES_BLOCK_ALL] forKey:@"cookies"];
            [appDelegate saveSettings:settings];
            [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookieAcceptPolicy:NSHTTPCookieAcceptPolicyNever];
        }
    } else {
        [appDelegate clearCookies];
        
        JFMinimalNotification *minimalNotification = [JFMinimalNotification notificationWithStyle:JFMinimalNotificationStyleDefault title:NSLocalizedString(@"Cleared cookies", nil) subTitle:nil dismissalDelay:2.0];
        minimalNotification.layer.zPosition = MAXFLOAT;
        [self.parentViewController.view addSubview:minimalNotification];
        [minimalNotification show];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end





@interface UserAgentTableViewController ()

@end

@implementation UserAgentTableViewController {
    int _currentRow;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.title = NSLocalizedString(@"User-Agent", nil);
    
    if ([self.tableView respondsToSelector:@selector(setCellLayoutMarginsFollowReadableWidth:)]) {
        self.tableView.cellLayoutMarginsFollowReadableWidth = NO;
    }
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 5;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    NSString *devicename;
    if (IS_IPAD) {
        devicename = @"iPad";
    } else {
        devicename = @"iPhone";
    }
    
    return [NSString stringWithFormat:NSLocalizedString(@"The user-agent is a string used to identificate the user's browser. Normalized user-agents show your browser without any specific information related to your device (%@, iOS %@).\n\nDefault: Normalized %@.", nil), devicename, [[UIDevice currentDevice] systemVersion], devicename];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithFrame:CGRectZero];
    }
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSMutableDictionary *settings = appDelegate.getSettings;
    NSInteger spoofUserAgent = [[settings valueForKey:@"uaspoof"] integerValue];
    
    if (indexPath.row == 0) {
        cell.textLabel.text = NSLocalizedString(@"Standard", nil);
        if (spoofUserAgent == UA_SPOOF_NO) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            _currentRow = 0;
        } else
            cell.accessoryType = UITableViewCellAccessoryNone;
    } else if (indexPath.row == 1) {
        cell.textLabel.text = NSLocalizedString(@"Normalized iPhone (iOS Safari)", nil);
        if (spoofUserAgent == UA_SPOOF_IPHONE) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            _currentRow = 1;
        } else
            cell.accessoryType = UITableViewCellAccessoryNone;
    } else if (indexPath.row == 2) {
        cell.textLabel.text = NSLocalizedString(@"Normalized iPad (iOS Safari)", nil);
        if (spoofUserAgent == UA_SPOOF_IPAD) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            _currentRow = 2;
        } else
            cell.accessoryType = UITableViewCellAccessoryNone;
    } else if (indexPath.row == 3) {
        cell.textLabel.text = NSLocalizedString(@"Windows 7 (NT 6.1), Firefox 24", nil);
        if (spoofUserAgent == UA_SPOOF_WIN7_TORBROWSER) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            _currentRow = 3;
        } else
            cell.accessoryType = UITableViewCellAccessoryNone;
    } else if (indexPath.row == 4) {
        cell.textLabel.text = NSLocalizedString(@"Mac OS X 10.9.2, Safari 7.0.3", nil);
        if (spoofUserAgent == UA_SPOOF_SAFARI_MAC) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            _currentRow = 4;
        } else
            cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSMutableDictionary *settings = appDelegate.getSettings;
    
    [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:_currentRow inSection:indexPath.section]].accessoryType = UITableViewCellAccessoryNone;
    [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryCheckmark;
    _currentRow = (int)indexPath.row;
    
    if (indexPath.row == 0) {
        [settings setObject:[NSNumber numberWithInteger:UA_SPOOF_NO] forKey:@"uaspoof"];
        [appDelegate saveSettings:settings];
    } else if (indexPath.row == 1) {
        [settings setObject:[NSNumber numberWithInteger:UA_SPOOF_IPHONE] forKey:@"uaspoof"];
        [appDelegate saveSettings:settings];
    } else if (indexPath.row == 2) {
        [settings setObject:[NSNumber numberWithInteger:UA_SPOOF_IPAD] forKey:@"uaspoof"];
        [appDelegate saveSettings:settings];
    } else if (indexPath.row == 3) {
        [settings setObject:[NSNumber numberWithInteger:UA_SPOOF_WIN7_TORBROWSER] forKey:@"uaspoof"];
        [appDelegate saveSettings:settings];
    } else if (indexPath.row == 4) {
        [settings setObject:[NSNumber numberWithInteger:UA_SPOOF_SAFARI_MAC] forKey:@"uaspoof"];
        [appDelegate saveSettings:settings];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}


@end





@interface ActiveContentTableViewController ()

@end

@implementation ActiveContentTableViewController {
    int _currentRow;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.title = NSLocalizedString(@"Active content", nil);
    
    if ([self.tableView respondsToSelector:@selector(setCellLayoutMarginsFollowReadableWidth:)]) {
        self.tableView.cellLayoutMarginsFollowReadableWidth = NO;
    }
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 3;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    return NSLocalizedString(@"Active content is a type of interactive or dynamic website content that includes programs like Internet polls, JavaScript applications, animated images, video and audio…\nActive content contains programs that trigger automatic actions on a Web page without the user's knowledge or consent.\n\nDefault: Block Ajax/Media/WebSockets.", nil);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithFrame:CGRectZero];
    }
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSMutableDictionary *settings = appDelegate.getSettings;
    NSInteger csp_setting = [[settings valueForKey:@"javascript"] integerValue];
    
    if (indexPath.row == 0) {
        cell.textLabel.text = NSLocalizedString(@"Allow all", nil);
        if (csp_setting == CONTENTPOLICY_PERMISSIVE) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            _currentRow = (int)indexPath.row;
        } else
            cell.accessoryType = UITableViewCellAccessoryNone;
    } else if (indexPath.row == 1) {
        cell.textLabel.text = NSLocalizedString(@"Block Ajax/Media/WebSockets", nil);
        if (csp_setting == CONTENTPOLICY_BLOCK_CONNECT) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            _currentRow = (int)indexPath.row;
        } else
            cell.accessoryType = UITableViewCellAccessoryNone;
    } else if (indexPath.row == 2) {
        cell.textLabel.text = NSLocalizedString(@"Block all active content", nil);
        if (csp_setting == CONTENTPOLICY_STRICT) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            _currentRow = (int)indexPath.row;
        } else
            cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSMutableDictionary *settings = appDelegate.getSettings;
    
    [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:_currentRow inSection:indexPath.section]].accessoryType = UITableViewCellAccessoryNone;
    [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryCheckmark;
    
    if (indexPath.row == 0) {
        [settings setObject:[NSNumber numberWithInteger:CONTENTPOLICY_PERMISSIVE] forKey:@"javascript"];
        [appDelegate saveSettings:settings];
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Security Warning", nil) message:NSLocalizedString(@"The 'Allow All' setting is UNSAFE and only recommended if a trusted site requires Ajax or WebSockets.\n\nWebSocket requests happen outside of Tor and will unmask your real IP address.", nil) preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:alert animated:YES completion:NULL];
        
        if (_currentRow != (int)indexPath.row)
            [(SettingsTableViewController *)self.navigationController.parentViewController setTabsNeedsRefresh:YES];
    } else if (indexPath.row == 1) {
        [settings setObject:[NSNumber numberWithInteger:CONTENTPOLICY_BLOCK_CONNECT] forKey:@"javascript"];
        [appDelegate saveSettings:settings];
        
        if (_currentRow != (int)indexPath.row)
            [(SettingsTableViewController *)self.navigationController.parentViewController setTabsNeedsRefresh:YES];
    } else if (indexPath.row == 2) {
        [settings setObject:[NSNumber numberWithInteger:CONTENTPOLICY_STRICT] forKey:@"javascript"];
        [appDelegate saveSettings:settings];
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Experimental Feature", nil) message:NSLocalizedString(@"Blocking all active content is an experimental feature.\n\nDisabling active content makes it harder for websites to identify your device, but websites will be able to tell that you are blocking scripts. This may be identifying information if you are the only user that blocks scripts.\n\nSome websites may not work if active content is blocked.\n\nBlocking may cause Tob to crash when loading script-heavy websites.", nil) preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:alert animated:YES completion:NULL];
        
        if (_currentRow != (int)indexPath.row)
            [(SettingsTableViewController *)self.navigationController.parentViewController setTabsNeedsRefresh:YES];
    }
    
    _currentRow = (int)indexPath.row;
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end





@interface TLSTableViewController ()

@end

@implementation TLSTableViewController {
    int _currentRow;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.title = NSLocalizedString(@"Minimum SSL/TLS protocol", nil);
    
    if ([self.tableView respondsToSelector:@selector(setCellLayoutMarginsFollowReadableWidth:)]) {
        self.tableView.cellLayoutMarginsFollowReadableWidth = NO;
    }
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 3;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    return NSLocalizedString(@"Minimum version of SSL/TLS required for HTTPS connections.\nNewer TLS protocols are more secure, but might not be supported by all sites.\n\nDefault : TLS 1.0+", nil);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithFrame:CGRectZero];
    }
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSMutableDictionary *settings = appDelegate.getSettings;
    NSInteger dntHeader = [[settings valueForKey:@"tlsver"] integerValue];
    
    if (indexPath.row == 0) {
        cell.textLabel.text = NSLocalizedString(@"SSL v3 (INSECURE)", nil);
        if (dntHeader == X_TLSVER_ANY) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            _currentRow = 0;
        } else
            cell.accessoryType = UITableViewCellAccessoryNone;
    } else if (indexPath.row == 1) {
        cell.textLabel.text = NSLocalizedString(@"TLS 1.0+", nil);
        if (dntHeader == X_TLSVER_TLS1) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            _currentRow = 1;
        } else
            cell.accessoryType = UITableViewCellAccessoryNone;
    } else if (indexPath.row == 2) {
        cell.textLabel.text = NSLocalizedString(@"TLS 1.2 only", nil);
        if (dntHeader == X_TLSVER_TLS1_2_ONLY) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            _currentRow = 2;
        } else
            cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSMutableDictionary *settings = appDelegate.getSettings;
    
    [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:_currentRow inSection:indexPath.section]].accessoryType = UITableViewCellAccessoryNone;
    [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryCheckmark;
    _currentRow = (int)indexPath.row;
    
    if (indexPath.row == 0) {
        [settings setObject:[NSNumber numberWithInteger:X_TLSVER_ANY] forKey:@"tlsver"];
        [appDelegate saveSettings:settings];
    } else if (indexPath.row == 1) {
        [settings setObject:[NSNumber numberWithInteger:X_TLSVER_TLS1] forKey:@"tlsver"];
        [appDelegate saveSettings:settings];
    } else if (indexPath.row == 2) {
        [settings setObject:[NSNumber numberWithInteger:X_TLSVER_TLS1_2_ONLY] forKey:@"tlsver"];
        [appDelegate saveSettings:settings];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end





@interface IPTableViewController ()

@end

@implementation IPTableViewController {
    int _currentRow;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.title = NSLocalizedString(@"IPv4/IPv6", nil);
    
    if ([self.tableView respondsToSelector:@selector(setCellLayoutMarginsFollowReadableWidth:)]) {
        self.tableView.cellLayoutMarginsFollowReadableWidth = NO;
    }
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 3;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    NSString *msg = NSLocalizedString(@"This is an advanced setting and should only be modified if you know what you are doing and if you have unusual network needs.", nil);
    
    NSInteger ipv6_status = [Ipv6Tester ipv6_status];
    msg = [msg stringByAppendingString:NSLocalizedString(@"\n\nCurrent autodetect state: ", nil)];
    if (ipv6_status == TOR_IPV6_CONN_ONLY) {
        msg = [msg stringByAppendingString:NSLocalizedString(@"IPv6-only detected", nil)];
    } else if (ipv6_status == TOR_IPV6_CONN_DUAL) {
        msg = [msg stringByAppendingString:NSLocalizedString(@"Dual-stack IPv4+IPv6 detected", nil)];
    } else if (ipv6_status == TOR_IPV6_CONN_FALSE) {
        msg = [msg stringByAppendingString:NSLocalizedString(@"IPv4-only detected", nil)];
    } else {
        msg = [msg stringByAppendingString:NSLocalizedString(@"Could not detect IP stack state. Using IPv4-only.", nil)];
    }
    
    msg = [msg stringByAppendingString:NSLocalizedString(@"\n\nDefault: Automatic IPv4/IPv6.", nil)];
    
    return msg;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithFrame:CGRectZero];
    }
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSMutableDictionary *settings = appDelegate.getSettings;
    NSInteger ipv4v6Setting = [[settings valueForKey:@"tor_ipv4v6"] integerValue];
    
    if (indexPath.row == 0) {
        cell.textLabel.text = NSLocalizedString(@"Automatic IPv4/IPv6", nil);
        
        if (ipv4v6Setting == OB_IPV4V6_AUTO) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            _currentRow = 0;
        }
    } else if (indexPath.row == 1) {
        cell.textLabel.text = NSLocalizedString(@"Always use IPv4", nil);
        
        if (ipv4v6Setting == OB_IPV4V6_V4ONLY) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            _currentRow = 1;
        }
    } else if (indexPath.row == 2) {
        cell.textLabel.text = NSLocalizedString(@"Always use IPv6", nil);
        
        if (ipv4v6Setting == OB_IPV4V6_V6ONLY) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            _currentRow = 2;
        }
    }
    
    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSMutableDictionary *settings = appDelegate.getSettings;
    
    [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:_currentRow inSection:indexPath.section]].accessoryType = UITableViewCellAccessoryNone;
    [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryCheckmark;
    _currentRow = (int)indexPath.row;
    
    if (indexPath.row == 0) {
        [settings setObject:[NSNumber numberWithInteger:OB_IPV4V6_AUTO] forKey:@"tor_ipv4v6"];
        [appDelegate saveSettings:settings];
    } else if (indexPath.row == 1) {
        [settings setObject:[NSNumber numberWithInteger:OB_IPV4V6_V4ONLY] forKey:@"tor_ipv4v6"];
        [appDelegate saveSettings:settings];
    } else if (indexPath.row == 2) {
        [settings setObject:[NSNumber numberWithInteger:OB_IPV4V6_V6ONLY] forKey:@"tor_ipv4v6"];
        [appDelegate saveSettings:settings];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSString *msg = NSLocalizedString(@"You may need to quit the app and restart it to change the connection method.\n\n(If you restart and the app stays stuck at \"Connecting...\", please come back and double-check your IP configuration).", nil);
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Setting saved", nil) message:msg preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Continue anyway", nil) style:UIAlertActionStyleCancel handler:nil]];
    UIAlertAction *restartAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Restart app", nil) style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        [appDelegate wipeAppData];
        exit(0);
    }];
    
    [alert addAction:restartAction];
    [alert setPreferredAction:restartAction];
    [self presentViewController:alert animated:YES completion:NULL];
}

@end





@interface WhitelistTableViewController ()

@end

@implementation WhitelistTableViewController {
    NSArray *domains;
    NSArray *filteredDomains;
    UISearchController *searchController;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.title = NSLocalizedString(@"Whitelist", nil);
    
    if ([self.tableView respondsToSelector:@selector(setCellLayoutMarginsFollowReadableWidth:)]) {
        self.tableView.cellLayoutMarginsFollowReadableWidth = NO;
    }
    
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(whitelistDomain)];
    self.navigationItem.rightBarButtonItem = addButton;
    
    domains = [[URLBlocker whitelistedDomains] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    searchController.searchResultsUpdater = self;
    searchController.dimsBackgroundDuringPresentation = NO;
    searchController.searchBar.delegate = self;
    self.tableView.tableHeaderView = searchController.searchBar;
    
    [searchController.searchBar sizeToFit]; // https://useyourloaf.com/blog/search-bar-not-showing-without-a-scope-bar/
    self.definesPresentationContext = YES;
    // [self.tableView setContentOffset:CGPointMake(0, searchController.searchBar.frame.size.height)];
}

- (void)whitelistDomain {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Whitelist domain", nil) message:@"" preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Add", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSString *domain = alertController.textFields.firstObject.text;
        [URLBlocker addDomainToWhitelist:domain];
        self->domains = [[URLBlocker whitelistedDomains] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
        [self searchForText:self->searchController.searchBar.text];

        [self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
    }];
    
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = NSLocalizedString(@"Domain", nil);
        textField.keyboardAppearance = UIKeyboardAppearanceDark;
        [textField addTarget:self action:@selector(alertTextFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
        
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        NSString *URL = [[[[appDelegate.tabsViewController contentViews] objectAtIndex:appDelegate.tabsViewController.currentIndex] url] absoluteString];
        
        if (URL.length > 0) {
            NSURL *currentURL = [NSURL URLWithString:URL];
            NSString *domain = currentURL.host;
            
            if ([domain hasPrefix:@"www."]) {
                if (domain.length > 4) {
                    domain = [domain substringFromIndex:4];
                } else {
                    domain = @"";
                }
            }
            textField.text = domain;
            [okAction setEnabled:domain.length > 0];
        } else {
            [okAction setEnabled:NO]; // Need at least 1 character
        }
    }];
    
    [alertController addAction:cancelAction];
    [alertController addAction:okAction];
    
    if ([alertController respondsToSelector:@selector(setPreferredAction:)]) {
        // This isn't available on iOS 8.
        // On iOS 8, StyleCancel is in bold
        [alertController setPreferredAction:okAction];
    }
    
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)alertTextFieldDidChange:(UITextField *)sender {
    UIAlertController *alertController = (UIAlertController *)self.presentedViewController;
    if (alertController) {
        UITextField *domainField = alertController.textFields.firstObject;
        UIAlertAction *okAction = alertController.actions.lastObject;
        okAction.enabled = domainField.text.length > 0;
    }
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (searchController.searchBar.text.length == 0) {
        return domains.count;
    } else if (section == 0) {
        return filteredDomains.count;
    }
    
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == 0) {
        return NSLocalizedString(@"The content blocker whitelist contains a list of domains for which the content blocker will allow ads. This can be useful is some websites block browser with ad-blockers.", nil);
    } else {
        return nil;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    NSString *domain;
    if (searchController.searchBar.text.length == 0) {
        // Didn't enter any search string
        domain = [domains objectAtIndex:indexPath.row];
    } else {
        domain = [filteredDomains objectAtIndex:indexPath.row];
    }
    cell.textLabel.text = domain;
    
    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSString *domain;
        if (searchController.searchBar.text.length == 0) {
            // Didn't enter any search string
            domain = [domains objectAtIndex:indexPath.row];
        } else {
            domain = [filteredDomains objectAtIndex:indexPath.row];
        }
        
        [URLBlocker removeDomainFromWhitelist:domain];
        domains = [[URLBlocker whitelistedDomains] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
        [self searchForText:searchController.searchBar.text];
        
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UIActionSheet *actionSheet;
    
    NSString *domain;
    if (searchController.searchBar.text.length == 0) {
        // Didn't enter any search string
        domain = [domains objectAtIndex:indexPath.row];
    } else {
        domain = [filteredDomains objectAtIndex:indexPath.row];
    }
    
    actionSheet = [[UIActionSheet alloc] initWithTitle:domain delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:NSLocalizedString(@"Delete", nil) otherButtonTitles:nil];
    
    [actionSheet setTag:indexPath.row];
    [actionSheet showInView:self.view];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}


#pragma mark - Search controller delegate

- (void)updateSearchResultsForSearchController:(UISearchController *)controller {
    NSString *searchString = controller.searchBar.text;
    [self searchForText:searchString];
    [self.tableView reloadData];
}

- (void)searchForText:(NSString *)searchText {
    if (searchText.length == 0) {
        filteredDomains = nil;
    } else {
        filteredDomains = [domains filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self BEGINSWITH[c] %@", searchText]];
    }
}


#pragma mark - Action sheet delegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSInteger row = [actionSheet tag];
    
    if (buttonIndex == actionSheet.cancelButtonIndex)
        return;
    
    NSString *domain;
    if (searchController.searchBar.text.length == 0) {
        // Didn't enter any search string
        domain = [domains objectAtIndex:row];
    } else {
        domain = [filteredDomains objectAtIndex:row];
    }

    [URLBlocker removeDomainFromWhitelist:domain];
    domains = [[URLBlocker whitelistedDomains] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    [self searchForText:searchController.searchBar.text];
    
    [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:row inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
}

@end





@interface RulesetTableViewController ()

@end

@implementation RulesetTableViewController {
    NSArray *hosts;
    NSArray *filteredHosts;
    UISearchController *searchController;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = NSLocalizedString(@"Ruleset", nil);
    
    if ([self.tableView respondsToSelector:@selector(setCellLayoutMarginsFollowReadableWidth:)]) {
        self.tableView.cellLayoutMarginsFollowReadableWidth = NO;
    }
    
    hosts = [[[URLBlocker blockers] allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    searchController.searchResultsUpdater = self;
    searchController.dimsBackgroundDuringPresentation = NO;
    searchController.searchBar.delegate = self;
    self.tableView.tableHeaderView = searchController.searchBar;
    
    [searchController.searchBar sizeToFit]; // https://useyourloaf.com/blog/search-bar-not-showing-without-a-scope-bar/
    self.definesPresentationContext = YES;
    [self.tableView setContentOffset:CGPointMake(0, searchController.searchBar.frame.size.height)];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (!searchController.isActive) {
        // Not searching, display ruleset info "header"
        return 2;
    } else {
        return 1;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (searchController.searchBar.text.length == 0) {
        // Didn't enter any search string
        if (section == 1 || searchController.isActive) {
            return hosts.count;
        }
    } else if (section == 0) {
        return filteredHosts.count;
    }
    
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == 0 && !searchController.isActive) {
        return NSLocalizedString(@"The content blocker ruleset contains a list of rules used to prevent ads from loading. This improves security and privacy while saving bandwidth.", nil);
    } else {
        return nil;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    NSString *domain;
    if (searchController.searchBar.text.length == 0) {
        // Didn't enter any search string
        domain = [hosts objectAtIndex:indexPath.row];
    } else {
        domain = [filteredHosts objectAtIndex:indexPath.row];
    }
    cell.textLabel.text = domain;
    cell.detailTextLabel.text = [[URLBlocker blockers] objectForKey:domain];
    
    BOOL isDisabled = [[URLBlocker disabledBlockers] containsObject:domain];
    [cell.textLabel setEnabled:!isDisabled];
    [cell.detailTextLabel setEnabled:!isDisabled];
    
    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UIActionSheet *actionSheet;
    
    NSString *domain;
    if (searchController.searchBar.text.length == 0) {
        // Didn't enter any search string
        domain = [hosts objectAtIndex:indexPath.row];
    } else {
        domain = [filteredHosts objectAtIndex:indexPath.row];
    }
    
    BOOL isDisabled = [[URLBlocker disabledBlockers] containsObject:domain];
    
    if (isDisabled) {
        actionSheet = [[UIActionSheet alloc] initWithTitle:domain delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Enable", nil), nil];
    } else {
        actionSheet = [[UIActionSheet alloc] initWithTitle:domain delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:NSLocalizedString(@"Disable", nil) otherButtonTitles:NSLocalizedString(@"Disable temporarly", nil), nil];
    }
    
    [actionSheet setTag:indexPath.row];
    [actionSheet showInView:self.view];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}


#pragma mark - Search controller delegate

- (void)updateSearchResultsForSearchController:(UISearchController *)controller {
    NSString *searchString = controller.searchBar.text;
    [self searchForText:searchString];
    [self.tableView reloadData];
}

- (void)searchForText:(NSString *)searchText {
    if (searchText.length == 0) {
        filteredHosts = nil;
    } else {
        filteredHosts = [hosts filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self BEGINSWITH[c] %@", searchText]];
    }
}


#pragma mark - Action sheet delegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSInteger row = [actionSheet tag];
    
    if (buttonIndex == actionSheet.cancelButtonIndex)
        return;
    
    NSString *domain;
    if (searchController.searchBar.text.length == 0) {
        // Didn't enter any search string
        domain = [hosts objectAtIndex:row];
    } else {
        domain = [filteredHosts objectAtIndex:row];
    }

    BOOL isDisabled = [[URLBlocker disabledBlockers] containsObject:domain];

    if (isDisabled) {
        [URLBlocker enableBlockerForHost:domain];
    } else {
        if (buttonIndex == actionSheet.destructiveButtonIndex) {
            [URLBlocker disableBlockerForHost:domain];
        } else {
            [URLBlocker temporarilyDisableBlockerForHost:domain];
        }
    }
    
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:row inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
}

@end





@interface CreditsWebViewController ()

@end

@implementation CreditsWebViewController {
    UIWebView *_webView;
    BOOL _allowLoad;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.title = NSLocalizedString(@"License", nil);
    
    _webView = [[UIWebView alloc] initWithFrame:self.view.frame];
    _webView.delegate = self;
    [self.view addSubview:_webView];
    
    _allowLoad = YES;
    NSString *htmlFile = [[NSBundle mainBundle] pathForResource:@"credits" ofType:@"html"];
    NSString* htmlString = [NSString stringWithContentsOfFile:htmlFile encoding:NSUTF8StringEncoding error:nil];
    [_webView loadHTMLString:htmlString baseURL:nil];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    CGRect frame = _webView.frame;
    frame.size = size;
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        self->_webView.frame = frame;
    } completion:nil];
}

- (BOOL)webView:(UIWebView*)webView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType {
    return _allowLoad;
}

- (void)webViewDidFinishLoad:(UIWebView*)webView {
    [webView stringByEvaluatingJavaScriptFromString:@"document.body.style.webkitTouchCallout='none'; document.body.style.KhtmlUserSelect='none'"];
    _allowLoad = NO;
}

@end
