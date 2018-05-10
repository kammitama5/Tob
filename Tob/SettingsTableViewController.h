//
//  SettingsTableViewController.h
//  OnionBrowser
//
//  Created by Mike Tigas on 5/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SettingsTableViewController : UITableViewController <UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate>

@property (nonatomic, retain) UIBarButtonItem *backButton;
@property (nonatomic) BOOL tabsNeedsRefresh;

- (void)goBack;

@end


@interface SearchEngineTableViewController : UITableViewController <UITableViewDataSource, UITableViewDelegate>
@end


@interface CookiesTableViewController : UITableViewController <UITableViewDataSource, UITableViewDelegate>
@end


@interface UserAgentTableViewController : UITableViewController <UITableViewDataSource, UITableViewDelegate>
@end


@interface ActiveContentTableViewController : UITableViewController <UITableViewDataSource, UITableViewDelegate>
@end


@interface TLSTableViewController : UITableViewController <UITableViewDataSource, UITableViewDelegate>
@end


@interface IPTableViewController : UITableViewController <UITableViewDataSource, UITableViewDelegate>
@end


@interface WhitelistTableViewController : UITableViewController <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UISearchResultsUpdating, UIActionSheetDelegate>
@end


@interface RulesetTableViewController : UITableViewController <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UISearchResultsUpdating, UIActionSheetDelegate>
@end


@interface CreditsWebViewController : UIViewController <UIWebViewDelegate>
@end
