//
//  ViewController.m
//  Tob
//
//  Created by Jean-Romain on 26/04/2016.
//  Copyright © 2016 JustKodding. All rights reserved.
//

#import "TabsViewController.h"
#import "AppDelegate.h"
#import "BookmarkTableViewController.h"
#import "SettingsTableViewController.h"
#import "TorCircuitTableViewController.h"
#import "Bookmark.h"
#import "BridgeViewController.h"
#import "NSStringPunycodeAdditions.h"
#import "iRate.h"
#import "LogViewController.h"
#import "MBProgressHUD.h"
#import "WebTextField.h"
#import <objc/runtime.h>

#define kNavigationBarAnimationTime 0.2

#define ALERTVIEW_SSL_WARNING 1
#define ALERTVIEW_EXTERN_PROTO 2
#define ALERTVIEW_INCOMING_URL 3
#define ALERTVIEW_TORFAIL 4

@interface TabsViewController () <UIScrollViewDelegate, UIWebViewDelegate, UITextFieldDelegate, UIGestureRecognizerDelegate>

@end

const char AlertViewExternProtoUrl;
const char AlertViewIncomingUrl;
static const CGFloat kRestoreAnimationDuration = 0.0f;
static const int kNewIdentityMaxTries = 3;

@implementation TabsViewController {
    // Array of contentviews that are displayed in the tabs
    NSMutableArray *_contentViews;
    
    // Web
    UIWebView *_webViewObject;
    
    // Nav bar
    WebTextField *_addressTextField;
    
    // Selected toolbar
    UIBarButtonItem *_backBarButtonItem;
    UIBarButtonItem *_forwardBarButtonItem;
    UIBarButtonItem *_settingsBarButtonItem;
    UIBarButtonItem *_onionBarButtonItem;
    UIBarButtonItem *_tabsBarButtonItem;
    
    // Deselected toolbar
    UIBarButtonItem *_clearAllBarButtonItem;
    
    // Tor progress view
    UIProgressView *_torProgressView;
    UIView *_torLoadingView;
    UIView *_torDarkBackgroundView;
    UILabel *_torProgressDescription;
    UILabel *_torLoadTimeWarning;
    
    // Tor panel view
    UIView *_torPanelView;
    UILabel *_IPAddressLabel;
    
    // Bookmarks
    BookmarkTableViewController *_bookmarks;
    
    // IP
    int _newIdentityTryCount;
}

#pragma mark - Initializing

- (id)init {
    self = [super init];
    if (self) {
        self.restorationIdentifier = @"tabsViewController";
        self.restorationClass = [self class];
        _newIdentityNumber = 0;
        _newIdentityTryCount = 0;
        
        [self initUI];
    }
    return self;
}

- (void)initUI {
    [self.scrollView setScrollsToTop:NO];
    
    _addressTextField = [[WebTextField alloc] init];
    [_addressTextField.stopButton addTarget:self action:@selector(stopTapped:) forControlEvents:UIControlEventTouchUpInside];
    [_addressTextField.refreshButton addTarget:self action:@selector(refreshTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.navBar setHidden:NO];
    [self.navBar setTextField:_addressTextField];
    [self.navBar hideCancelButtonAnimated:NO];
    [_addressTextField setDelegate:self];
    [_addressTextField setAutoresizingMask:UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth];
    
    [self.navBar.progressView setProgress:0.0f animated:NO];
    [self hideProgressBarAnimated:NO];
    
    // Add a "close all" button to the deselected toolbar
    NSMutableArray *items = [[NSMutableArray alloc] initWithArray:self.deselectedToolbar.items];
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    [items insertObject:flexibleSpace atIndex:0];
    [items insertObject:self.clearAllBarButtonItem atIndex:0];
    self.deselectedToolbar.items = items;
    
    _tabsBarButtonItem = [self.selectedToolbar.items objectAtIndex:1];
    
    // Add a loading view for Tor
    _torDarkBackgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    _torDarkBackgroundView.backgroundColor = [UIColor blackColor];
    _torDarkBackgroundView.alpha = 0.5;
    [self.view addSubview:_torDarkBackgroundView];
    
    _torLoadingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 300, 140)];
    _torLoadingView.center = self.view.center;
    _torLoadingView.layer.cornerRadius = 5.0f;
    _torLoadingView.layer.masksToBounds = YES;

    UILabel *titleProgressLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 10, _torLoadingView.frame.size.width, 30)];
    titleProgressLabel.text = NSLocalizedString(@"Initializing Tor…", nil);
    titleProgressLabel.textAlignment = NSTextAlignmentCenter;
    [_torLoadingView addSubview:titleProgressLabel];

    UIButton *settingsButton = [[UIButton alloc] initWithFrame:CGRectMake(_torLoadingView.frame.size.width - 40, 10, 30, 30)];
    [settingsButton setImage:[[UIImage imageNamed:@"Settings"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [settingsButton addTarget:self action:@selector(settingsTapped:) forControlEvents:UIControlEventTouchUpInside];
    [_torLoadingView addSubview:settingsButton];
    
    UIButton *logButton = [[UIButton alloc] initWithFrame:CGRectMake(13, 13, 24, 24)];
    [logButton setImage:[[UIImage imageNamed:@"Log"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [logButton addTarget:self action:@selector(showLog) forControlEvents:UIControlEventTouchUpInside];
    [_torLoadingView addSubview:logButton];
    
    _torProgressView = [[UIProgressView alloc] initWithFrame:CGRectMake(10, 50, _torLoadingView.frame.size.width - 20, 10)];
    [_torLoadingView addSubview:_torProgressView];
    
    _torProgressDescription = [[UILabel alloc] initWithFrame:CGRectMake(10, 60, _torLoadingView.frame.size.width - 20, 30)];
    _torProgressDescription.numberOfLines = 1;
    _torProgressDescription.textAlignment = NSTextAlignmentCenter;
    _torProgressDescription.adjustsFontSizeToFitWidth = YES;
    _torProgressDescription.text = @"0% - Starting";
    [_torLoadingView addSubview:_torProgressDescription];
    
    _torLoadTimeWarning = [[UILabel alloc] initWithFrame:CGRectMake(10, 90, _torLoadingView.frame.size.width - 20, 40)];
    _torLoadTimeWarning.numberOfLines = 3;
    _torLoadTimeWarning.textAlignment = NSTextAlignmentCenter;
    _torLoadTimeWarning.text = NSLocalizedString(@"This may take up to a couple of minutes. If it remains stuck, check-out bridges or try restarting the app.", nil);
    [_torLoadTimeWarning setFont:[UIFont systemFontOfSize:11]];
    [_torLoadingView addSubview:_torLoadTimeWarning];

    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate.logViewController logInfo:@"[Tor] 0% - Starting"];
    
    [self.view addSubview:_torLoadingView];
    
    if (appDelegate.doPrepopulateBookmarks){
        [self prePopulateBookmarks];
    }
    
    [self restoreData];
    [self updateTintColor];
    [self updateNavigationItems];
}

- (void)updateTintColor {
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSMutableDictionary *settings = appDelegate.getSettings;
    
    if (![[settings valueForKey:@"night-mode"] boolValue]) {
        [self.view setBackgroundColor:[UIColor groupTableViewBackgroundColor]];
        [self.scrollView setBackgroundColor:[UIColor groupTableViewBackgroundColor]];

        self.navBar.cancelButton.tintColor = self.view.tintColor;
        
        _addressTextField.backgroundColor = [UIColor whiteColor];
        _addressTextField.textColor = [UIColor blackColor];
        _addressTextField.tintColor = self.view.tintColor;
        _addressTextField.tlsButton.tintColor = [UIColor grayColor];
        _addressTextField.stopButton.tintColor = [UIColor blackColor];
        _addressTextField.refreshButton.tintColor = [UIColor blackColor];
        _addressTextField.layer.borderColor = [UIColor colorWithWhite:0.8 alpha:1.0].CGColor;
        [_addressTextField setNeedsDisplay];
        
        // Use custom colors for the page control (to make it more visible)
        self.pageControl.tintColor = [UIColor darkGrayColor];
        self.pageControl.pageIndicatorTintColor = [UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:1.0];
        self.pageControl.currentPageIndicatorTintColor = [UIColor grayColor];
        
        // Use a custom appearence for the navigation bar
        [self.navBar setBackgroundColor:[UIColor groupTableViewBackgroundColor]];
        [self.navBar setTintColor:self.view.tintColor];
        
        self.navBar.progressView.trackTintColor = [UIColor colorWithRed:0.90 green:0.90 blue:0.92 alpha:1.0];
        self.navBar.progressView.progressTintColor = self.view.tintColor;
        _torProgressView.trackTintColor = [UIColor colorWithRed:0.80 green:0.80 blue:0.82 alpha:1.0];;
        _torProgressView.progressTintColor = self.view.tintColor;
        
        _torLoadingView.backgroundColor = [UIColor groupTableViewBackgroundColor];
        
        for (UIView *subview in [_torLoadingView subviews]) {
            if ([subview class] == [UILabel class] && subview != _torLoadTimeWarning)
                [(UILabel *)subview setTextColor:[UIColor blackColor]];
            else if ([subview class] == [UIButton class])
                [(UIButton *) subview setTintColor:self.view.tintColor];
        }
        
        _torLoadTimeWarning.textColor = [UIColor grayColor];
        _torProgressDescription.textColor = [UIColor blackColor];
        
        _tabsBarButtonItem.tintColor = self.view.tintColor;
        self.numberOfTabsLabel.textColor = self.view.tintColor;
        self.tabTitleLabel.textColor = [UIColor blackColor];

        [self.selectedToolbar setBarTintColor:[UIColor groupTableViewBackgroundColor]];
        [self.deselectedToolbar setBarTintColor:[UIColor groupTableViewBackgroundColor]];
        [self.selectedToolbar setTintColor:self.view.tintColor];
        [self.deselectedToolbar setTintColor:self.view.tintColor];
        self.selectedToolbar.translucent = YES;
        
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
    } else {
        [self.view setBackgroundColor:[UIColor grayColor]];
        [self.scrollView setBackgroundColor:[UIColor grayColor]];
        
        self.navBar.cancelButton.tintColor = [UIColor whiteColor];
        
        _addressTextField.backgroundColor = [UIColor lightGrayColor];
        _addressTextField.textColor = [UIColor whiteColor];
        _addressTextField.tintColor = [UIColor whiteColor];
        _addressTextField.tlsButton.tintColor = [UIColor whiteColor];
        _addressTextField.stopButton.tintColor = [UIColor whiteColor];
        _addressTextField.refreshButton.tintColor = [UIColor whiteColor];
        _addressTextField.layer.borderColor = [UIColor colorWithWhite:0.75 alpha:1.0].CGColor;
        [_addressTextField setNeedsDisplay];

        self.pageControl.tintColor = [UIColor whiteColor];
        self.pageControl.pageIndicatorTintColor = [UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:1.0];
        self.pageControl.currentPageIndicatorTintColor = [UIColor whiteColor];
        
        [self.navBar setBackgroundColor:[UIColor darkGrayColor]];
        [self.navBar setTintColor:[UIColor whiteColor]];
        
        self.navBar.progressView.trackTintColor = [UIColor lightGrayColor];
        self.navBar.progressView.progressTintColor = [UIColor whiteColor];
        _torProgressView.trackTintColor = [UIColor grayColor];
        _torProgressView.progressTintColor = [UIColor whiteColor];
        
        _torLoadingView.backgroundColor = [UIColor darkGrayColor];
        
        for (UIView *subview in [_torLoadingView subviews]) {
            if ([subview class] == [UILabel class] && subview != _torLoadTimeWarning)
                [(UILabel *)subview setTextColor:[UIColor whiteColor]];
            else if ([subview class] == [UIButton class])
                [(UIButton *) subview setTintColor:[UIColor whiteColor]];
        }
        
        _torLoadTimeWarning.textColor = [UIColor lightGrayColor];
        _torProgressDescription.textColor = [UIColor whiteColor];
        
        _tabsBarButtonItem.tintColor = [UIColor whiteColor];
        self.numberOfTabsLabel.textColor = [UIColor whiteColor];
        self.tabTitleLabel.textColor = [UIColor whiteColor];

        [self.selectedToolbar setBarTintColor:[UIColor darkGrayColor]];
        [self.deselectedToolbar setBarTintColor:[UIColor darkGrayColor]];
        [self.selectedToolbar setTintColor:[UIColor whiteColor]];
        [self.deselectedToolbar setTintColor:[UIColor whiteColor]];
        self.selectedToolbar.translucent = YES;
        
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updateTintColor];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self setAutomaticallyAdjustsScrollViewInsets:YES];
    [self setExtendedLayoutIncludesOpaqueBars:YES];
    
    if (!self.tabsAreVisible) {
        [self.view bringSubviewToFront:self.selectedToolbar];
        [self.view bringSubviewToFront:_bookmarks.tableView];
        [self.view bringSubviewToFront:_torDarkBackgroundView];
        [self.view bringSubviewToFront:_torLoadingView];
        [self.view bringSubviewToFront:_torPanelView];
        
        if ([[[self contentViews] objectAtIndex:self.currentIndex] needsForceRefresh])
            [self refreshCurrentTab];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self->_torDarkBackgroundView setFrame:CGRectMake(0, 0, size.width, size.height)];
        [self->_torLoadingView setCenter:CGPointMake(size.width / 2, size.height / 2)];
        [self->_torPanelView setCenter:CGPointMake(size.width / 2, size.height / 2)];
        
        [self.view bringSubviewToFront:self->_torDarkBackgroundView];
        [self.view bringSubviewToFront:self->_torLoadingView];
        [self.view bringSubviewToFront:self->_torPanelView];
        
        [self->_bookmarks.view setFrame:CGRectMake(0, [[UIApplication sharedApplication] statusBarFrame].size.height + 44, size.width, size.height - ([[UIApplication sharedApplication] statusBarFrame].size.height + 44))];
    } completion:nil];
}

- (void)saveAppState {
    NSMutableArray *tabsDataArray = [[NSMutableArray alloc] initWithCapacity:self.tabsCount];
    for (int i = 0; i < self.tabsCount; i++) {
        if ([[[self.contentViews objectAtIndex:i] url] absoluteString]) {
            [tabsDataArray addObject:@{@"url" : [[[self.contentViews objectAtIndex:i] url] absoluteString], @"title" : [[self tabAtIndex:i] title]}];
        }
    }
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *appFile = [documentsDirectory stringByAppendingPathComponent:@"state.bin"];
    [NSKeyedArchiver archiveRootObject:@[[NSNumber numberWithInt:self.currentIndex], tabsDataArray] toFile:appFile];
}

- (void)getRestorableData {
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *appFile = [documentsDirectory stringByAppendingPathComponent:@"state.bin"];
    
    if ([[appDelegate.getSettings valueForKey:@"save-app-state"] boolValue]) {
        NSMutableArray *dataArray = [NSKeyedUnarchiver unarchiveObjectWithFile:appFile];
        
        if ([dataArray count] == 2) {
            appDelegate.restoredIndex = [[dataArray objectAtIndex:0] intValue];
            appDelegate.restoredData = [dataArray objectAtIndex:1];
        }
    } else {
        [[NSFileManager defaultManager] removeItemAtPath:appFile error:nil];
        appDelegate.restoredIndex = 0;
        appDelegate.restoredData = nil;
    }
}

- (void)restoreData {
    [self getRestorableData];

    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if ([appDelegate restoredData] && [[appDelegate restoredData] count] > 0) {
        for (int i = 0; i < [appDelegate restoredData].count; i++) {
            NSDictionary *params = [appDelegate restoredData][i];
            MTPageViewTab *restoredTab = [self addTabAnimated:NO];
            
            [restoredTab setTitle:[params objectForKey:@"title"]];
            [[self.contentViews lastObject] setUrl:[NSURL URLWithString:[params objectForKey:@"url"]]];
        }
    }
    
    if ([appDelegate startUrl]) {
        [appDelegate.logViewController logInfo:[NSString stringWithFormat:@"[Browser] Started app with URL %@", [[appDelegate startUrl] absoluteString]]];
        MTPageViewTab *newTab = [self addTabAnimated:NO];
        [newTab setTitle:[[appDelegate startUrl] host]];
        [[self.contentViews lastObject] setUrl:[appDelegate startUrl]];
    }
    
    if (self.tabsCount == 0) {
        NSString *homepage = [appDelegate homepage];
        [self addTabWithTitle:homepage animated:NO];
        [[self.contentViews lastObject] setUrl:[NSURL URLWithString:homepage]];
    }
    
    // Select the restored/opened tab
    if ([appDelegate startUrl]) {
        [UIView animateWithDuration:kRestoreAnimationDuration animations:^{
            [self scrollToIndex:[self tabsCount] - 1 animated:NO];
        } completion:^(BOOL finished){
            [self hideTabsAnimated:NO];
        }];
    } else if ([appDelegate restoredData] && [appDelegate restoredIndex] != self.currentIndex) {
        [UIView animateWithDuration:kRestoreAnimationDuration animations:^{
            [self scrollToIndex:[appDelegate restoredIndex] animated:NO];
        } completion:^(BOOL finished){
            if (self.currentIndex != 0)
                ([self.contentViews objectAtIndex:0]).frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
            
            [self hideTabsAnimated:NO];
            [self.view bringSubviewToFront:self->_torDarkBackgroundView];
            [self.view bringSubviewToFront:self->_torLoadingView];
        }];
    }
}

- (void)setNewIdentityNumber:(int)newIdentityNumber {
    _newIdentityNumber = newIdentityNumber;
    _newIdentityTryCount = 0;
}


#pragma mark - UIViewController Methods

- (NSMutableArray *)contentViews {
    if (!_contentViews) {
        _contentViews = [[NSMutableArray alloc] init];
    }
    return _contentViews;
}

- (UIBarButtonItem *)backBarButtonItem {
    if (!_backBarButtonItem) {
        _backBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[[UIImage imageNamed:@"Backward"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]
                                                              style:UIBarButtonItemStylePlain
                                                             target:self
                                                             action:@selector(goBackTapped:)];
    }
    return _backBarButtonItem;
}

- (UIBarButtonItem *)forwardBarButtonItem {
    if (!_forwardBarButtonItem) {
        _forwardBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[[UIImage imageNamed:@"Forward"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]
                                                                 style:UIBarButtonItemStylePlain
                                                                target:self
                                                                action:@selector(goForwardTapped:)];
        _forwardBarButtonItem.width = 18.0f;
    }
    return _forwardBarButtonItem;
}

- (UIBarButtonItem *)settingsBarButtonItem {
    if (!_settingsBarButtonItem) {
        _settingsBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[[UIImage imageNamed:@"Settings"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]
                                                                  style:UIBarButtonItemStylePlain
                                                                 target:self
                                                                 action:@selector(settingsTapped:)];
    }
    return _settingsBarButtonItem;
}

- (UIBarButtonItem *)onionBarButtonItem {
    if (!_onionBarButtonItem) {
        _onionBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[[UIImage imageNamed:@"Onion"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] style:UIBarButtonItemStylePlain target:self action:@selector(onionTapped:)];
    }
    return _onionBarButtonItem;
}

- (UIBarButtonItem *)clearAllBarButtonItem {
    if (!_clearAllBarButtonItem) {
        _clearAllBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(clearAllTapped:)];
    }
    return _clearAllBarButtonItem;
}

- (void)updateNavigationItems {
    if (![_addressTextField isEditing] && [self.tabContainers count] > self.currentIndex)
        _addressTextField.text = [[(CustomWebView *)[self.contentViews objectAtIndex:self.currentIndex] url] absoluteString];
    
    self.backBarButtonItem.enabled = _webViewObject.canGoBack;
    self.forwardBarButtonItem.enabled = _webViewObject.canGoForward;
    
    UIButton *refreshStopButton = _webViewObject.isLoading ? _addressTextField.stopButton : _addressTextField.refreshButton;
    refreshStopButton.alpha = _addressTextField.text.length > 0;
    
    _addressTextField.rightView = refreshStopButton;

    UIBarButtonItem *fixedSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    NSArray *items = [NSArray arrayWithObjects:fixedSpace, self.backBarButtonItem, flexibleSpace, self.forwardBarButtonItem, flexibleSpace, self.settingsBarButtonItem, flexibleSpace, self.onionBarButtonItem, flexibleSpace, _tabsBarButtonItem, fixedSpace, nil];
    
    self.selectedToolbar.items = items;
    
    [self updateDisplayedTitle];
}

- (void)updateProgress:(float)progress animated:(BOOL)animated {
    [self.navBar.progressView setProgress:progress animated:animated];
}

- (void)showProgressBarAnimated:(BOOL)animated {
    if (animated)
        [UIView animateWithDuration:0.2 animations:^{
            [self.navBar.progressView setAlpha:1.0f];
        }];
    else
        [self.navBar.progressView setAlpha:1.0f];
}

- (void)hideProgressBarAnimated:(BOOL)animated {
    if (animated)
        [UIView animateWithDuration:0.2 animations:^{
            [self.navBar.progressView setAlpha:0.0f];
        }];
    else
        [self.navBar.progressView setAlpha:0.0f];
}

- (void)prePopulateBookmarks {
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    NSManagedObjectContext *context = [appDelegate managedObjectContext];
    NSError *error = nil;

    NSUInteger i = 0;
    
    /*
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    path = [path stringByAppendingPathComponent:@"bookmarks.plist"];
    Boolean restored = NO;
    
    // Attempt to restore old bookmarks
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:path]) {
        NSDictionary *bookmarks = [[NSDictionary alloc] initWithContentsOfFile:path];
        
        NSNumber *v = [bookmarks objectForKey:@"version"];
        if (v != nil) {
            NSArray *tlist = [bookmarks objectForKey:@"bookmarks"];
            for (int i = 0; i < [tlist count]; i++) {
                Bookmark *bookmark = (Bookmark *)[NSEntityDescription insertNewObjectForEntityForName:@"Bookmark" inManagedObjectContext:context];
                [bookmark setTitle:[tlist[i] objectForKey:@"name"]];
                [bookmark setUrl:[tlist[i] objectForKey:@"url"]];
                [bookmark setOrder:i];
            }
        }
        
        if ([context save:&error])
            restored = YES;
        
        [fileManager removeItemAtPath:path error:nil];
    }
    
    if (!restored) {
        Bookmark *bookmark;
        
        bookmark = (Bookmark *)[NSEntityDescription insertNewObjectForEntityForName:@"Bookmark" inManagedObjectContext:context];
        [bookmark setTitle:NSLocalizedString(@"Search: DuckDuckGo", nil)];
        [bookmark setUrl:@"http://3g2upl4pq6kufc4m.onion/html/"];
        [bookmark setOrder:i++];
        
        bookmark = (Bookmark *)[NSEntityDescription insertNewObjectForEntityForName:@"Bookmark" inManagedObjectContext:context];
        [bookmark setTitle:NSLocalizedString(@"Search: DuckDuckGo (Plain HTTPS)", nil)];
        [bookmark setUrl:@"https://duckduckgo.com/html/"];
        [bookmark setOrder:i++];
        
        bookmark = (Bookmark *)[NSEntityDescription insertNewObjectForEntityForName:@"Bookmark" inManagedObjectContext:context];
        [bookmark setTitle:NSLocalizedString(@"IP Address Check", nil)];
        [bookmark setUrl:@"https://duckduckgo.com/lite/?q=what+is+my+ip"];
        [bookmark setOrder:i++];
        
        if (![context save:&error]) {
            NSLog(@"Error adding bookmarks: %@", error);
        }
    }
     */
    
    Bookmark *bookmark = (Bookmark *)[NSEntityDescription insertNewObjectForEntityForName:@"Bookmark" inManagedObjectContext:context];
    [bookmark setTitle:NSLocalizedString(@"Search: DuckDuckGo", nil)];
    [bookmark setUrl:@"https://3g2upl4pq6kufc4m.onion/html/"];
    [bookmark setOrder:i++];
    
    bookmark = (Bookmark *)[NSEntityDescription insertNewObjectForEntityForName:@"Bookmark" inManagedObjectContext:context];
    [bookmark setTitle:NSLocalizedString(@"Search: DuckDuckGo (Plain HTTPS)", nil)];
    [bookmark setUrl:@"https://duckduckgo.com/html/"];
    [bookmark setOrder:i++];
    
    bookmark = (Bookmark *)[NSEntityDescription insertNewObjectForEntityForName:@"Bookmark" inManagedObjectContext:context];
    [bookmark setTitle:NSLocalizedString(@"IP Address Check", nil)];
    [bookmark setUrl:@"https://duckduckgo.com/lite/?q=what+is+my+ip"];
    [bookmark setOrder:i++];
    
    if (![context save:&error]) {
        NSLog(@"Error adding bookmarks: %@", error);
    }
}

-(NSString *)isURL:(NSString *)userInput {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"TLDs" ofType:@"json"];
    NSString *jsonString = [[NSString alloc] initWithContentsOfFile:path encoding:NSUTF8StringEncoding error:NULL];
    NSArray *urlEndings;
    
    if (!jsonString) {
#ifdef DEBUG
        NSLog(@"TLDs.json file not found! Defaulting to a shorter list.");
#endif
        urlEndings = @[@".com",@".co",@".net",@".io",@".org",@".edu",@".to",@".ly",@".gov",@".eu",@".cn",@".mil",@".gl",@".info",@".onion",@".uk",@".fr"];
    } else {
        NSError *error = nil;
        NSData *data = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
        urlEndings = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
        
        if (error) {
#ifdef DEBUG
            NSLog(@"TLDs.json file not found! Defaulting to a shorter list.");
#endif
            urlEndings = @[@".com",@".co",@".net",@".io",@".org",@".edu",@".to",@".ly",@".gov",@".eu",@".cn",@".mil",@".gl",@".info",@".onion",@".uk",@".fr"];
        }
    }
    
    NSString *workingInput = @"";
    
    // Check if it's escaped
    if (![[userInput stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding] isEqualToString:userInput])
        return nil;
    
    // Check if it's an IP address
    BOOL isIP = YES;
    NSString *ipString = [userInput stringByReplacingOccurrencesOfString:@"http://" withString:@""];
    ipString = [ipString stringByReplacingOccurrencesOfString:@"http://" withString:@""];
    
    if ([ipString rangeOfString: @"/"].location != NSNotFound)
        ipString = [ipString substringWithRange:NSMakeRange(0, [ipString rangeOfString: @"/"].location)];
    if ([ipString rangeOfString: @":"].location != NSNotFound)
        ipString = [ipString substringWithRange:NSMakeRange(0, [ipString rangeOfString: @":"].location)];
    
    NSArray *components = [ipString componentsSeparatedByString:@"."];
    if (components.count != 4)
        isIP = NO;

    NSCharacterSet *unwantedCharacters = [[NSCharacterSet characterSetWithCharactersInString:@"0123456789."] invertedSet];
    if ([ipString rangeOfCharacterFromSet:unwantedCharacters].location != NSNotFound)
        isIP = NO;

    for (NSString *string in components) {
        if ((string.length < 1) || (string.length > 3 )) {
            isIP = NO;
        }
        if (string.intValue > 255) {
            isIP = NO;
        }
    }
    if  ([[components objectAtIndex:0]intValue]==0){
        isIP = NO;
    }
    
    if (isIP) {
        if (![userInput hasPrefix:@"http://"] && ![userInput hasPrefix:@"https://"])
            userInput = [@"http://" stringByAppendingString:userInput];
            
        return userInput;
    }
    
    // If the string is just an extension (ex: "com"), it's not a real URL
    if ([urlEndings containsObject:userInput] || [urlEndings containsObject:[NSString stringWithFormat:@".%@", userInput]]) {
        return nil;
    }
    
    // Check if it's another type of URL
    if ([userInput hasPrefix:@"http://"] || [userInput hasPrefix:@"https://"])
        workingInput = userInput;
    else if ([userInput hasPrefix:@"www."])
        workingInput = [@"http://" stringByAppendingString:userInput];
    else if ([userInput hasPrefix:@"m."])
        workingInput = [@"http://" stringByAppendingString:userInput];
    else if ([userInput hasPrefix:@"mobile."])
        workingInput = [@"http://" stringByAppendingString:userInput];
    else
        workingInput = [@"http://" stringByAppendingString:userInput];
    
    NSURL *url = [NSURL URLWithString:workingInput];
    for (NSString *extension in urlEndings) {
        if ([url.host hasSuffix:extension]) {
            return workingInput;
        }
    }
    
    return nil;
}

- (void)loadURL:(NSURL *)url {    
    NSString *urlProto = [[url scheme] lowercaseString];
    
    if ([urlProto isEqualToString:@"tob"]) {
        NSString *newUrl = [url absoluteString];
        newUrl = [newUrl stringByReplacingOccurrencesOfString:@"tob" withString:@"http" options:NSLiteralSearch range:[newUrl rangeOfString:@"tob"]];
        url = [NSURL URLWithString:newUrl];
    } else if ([urlProto isEqualToString:@"tobs"]) {
        NSString *newUrl = [url absoluteString];
        newUrl = [newUrl stringByReplacingOccurrencesOfString:@"tobs" withString:@"https" options:NSLiteralSearch range:[newUrl rangeOfString:@"tobs"]];
        url = [NSURL URLWithString:newUrl];
    }
    
    if ([urlProto isEqualToString:@"http"] || [urlProto isEqualToString:@"https"]) {
        /***** One of our supported protocols *****/
        
        // Cancel any existing nav
        [_webViewObject stopLoading];
        
        // Build request and go.
        _webViewObject.scalesPageToFit = YES;
        NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
        [req setHTTPShouldUsePipelining:YES];
        [_webViewObject loadRequest:req];
        
        if ([urlProto isEqualToString:@"https"]) {
            [(CustomWebView *)_webViewObject updateTLSStatus:TLSSTATUS_SECURE];
        } else if (urlProto && ![urlProto isEqualToString:@""]) {
            [(CustomWebView *)_webViewObject updateTLSStatus:TLSSTATUS_INSECURE];
        } else {
            [(CustomWebView *)_webViewObject updateTLSStatus:TLSSTATUS_HIDDEN];
        }
    } else {
        /***** NOT a protocol that this app speaks, check with the OS if the user wants to *****/
        if ([[UIApplication sharedApplication] canOpenURL:url]) {
            //NSLog(@"can open %@", [navigationURL absoluteString]);
            NSString *msg = [NSString stringWithFormat:NSLocalizedString(@"Tob cannot load a '%@' link, but another app you have installed can.\n\nNote that the other app will not load data over Tor, which could leak identifying information.\n\nDo you wish to proceed?", nil), url.scheme, nil];
            UIAlertView *alertView = [[UIAlertView alloc]
                                      initWithTitle:NSLocalizedString(@"Open Other App?", nil)
                                      message:msg
                                      delegate:nil
                                      cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                      otherButtonTitles:NSLocalizedString(@"Open", nil), nil];
            alertView.delegate = self;
            alertView.tag = ALERTVIEW_EXTERN_PROTO;
            [alertView show];
            objc_setAssociatedObject(alertView, &AlertViewExternProtoUrl, url, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            return;
        } else {
            NSLog(@"cannot open %@", [url absoluteString]);
            return;
        }
    }
}

- (void)askToLoadURL:(NSURL *)url {
    /* Used on startup, if we opened the app from an outside source.
     * Will ask for user permission and display requested URL so that
     * the user isn't tricked into visiting a URL that includes their
     * IP address (or other info) that an attack site included when the user
     * was on the attack site outside of Tor.
     */
    NSString *msg = [NSString stringWithFormat:NSLocalizedString(@"Another app has requested that Tob load the following link. Because the link is generated outside of Tor, please ensure that you trust the link & that the URL does not contain identifying information. Canceling will open the normal homepage.\n\n%@", nil), url.absoluteString, nil];
    UIAlertView* alertView = [[UIAlertView alloc]
                              initWithTitle:NSLocalizedString(@"Open This URL?", nil)
                              message:msg
                              delegate:self
                              cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                              otherButtonTitles:NSLocalizedString(@"Open This Link", nil), nil];
    
    alertView.tag = ALERTVIEW_INCOMING_URL;
    [alertView show];
    objc_setAssociatedObject(alertView, &AlertViewIncomingUrl, url, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)addNewTabForURL:(NSURL *)url {
    [UIView animateWithDuration:(0.4) animations:^{
        [self addTabWithTitle:url.absoluteString];
        self.selectedToolbar.frame = CGRectMake(0, self.view.frame.size.height - 44, self.view.frame.size.width, 44);
    } completion:^(BOOL finished) {
        if (!finished)
            return;
        
        NSString *urlProto = [[url scheme] lowercaseString];
        if ([urlProto isEqualToString:@"https"]) {
            [(CustomWebView *)[[self contentViews] lastObject] updateTLSStatus:TLSSTATUS_SECURE];
        } else if (urlProto && ![urlProto isEqualToString:@""]) {
            [(CustomWebView *)[[self contentViews] lastObject] updateTLSStatus:TLSSTATUS_INSECURE];
        } else {
            [(CustomWebView *)[[self contentViews] lastObject] updateTLSStatus:TLSSTATUS_HIDDEN];
        }

        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        [[self.contentViews objectAtIndex:self.tabsCount - 1] loadRequest:request];
        [self.view bringSubviewToFront:self.selectedToolbar];
    }];
}

- (void)stopLoading {
    for (CustomWebView *tab in self.contentViews) {
        [tab stopLoading];
    }
}

- (void)updateTorProgress:(NSNumber *)progress {
    [_torProgressView setProgress:[progress floatValue] animated:YES];
}

- (void)refreshCurrentTab {
    if (_webViewObject) {
        [_webViewObject reload];
        [[[self contentViews] objectAtIndex:self.currentIndex] setNeedsForceRefresh:NO];
    }
}

- (void)setTabsNeedForceRefresh:(BOOL)needsForceRefresh {
    for (int i = 0; i < self.tabsCount; i++) {
        [[[self contentViews] objectAtIndex:i] setNeedsForceRefresh:needsForceRefresh];
    }
}

- (void)removeTorProgressView {
    [_torLoadingView removeFromSuperview];
    [_torDarkBackgroundView removeFromSuperview];
    _torLoadingView = nil;
    _torDarkBackgroundView = nil;
    
    [self setTabsNeedForceRefresh:YES];
    
    // Load the current tab
    NSURL *url = [[self.contentViews objectAtIndex:self.currentIndex] url];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [[[self contentViews] objectAtIndex:self.currentIndex] setNeedsForceRefresh:NO];
    
    NSString *urlProto = [[url scheme] lowercaseString];
    if ([urlProto isEqualToString:@"https"]) {
        [(CustomWebView *)[[self contentViews] objectAtIndex:self.currentIndex] updateTLSStatus:TLSSTATUS_SECURE];
    } else if (urlProto && ![urlProto isEqualToString:@""]){
        [(CustomWebView *)[[self contentViews] objectAtIndex:self.currentIndex] updateTLSStatus:TLSSTATUS_INSECURE];
    } else {
        [(CustomWebView *)[[self contentViews] objectAtIndex:self.currentIndex] updateTLSStatus:TLSSTATUS_HIDDEN];
    }

    [[[self contentViews] objectAtIndex:self.currentIndex] loadRequest:request];
    
    if ([[_addressTextField text] isEqualToString:@""] && ![_webViewObject isLoading]) {
        [_addressTextField becomeFirstResponder];
    }
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    appDelegate.restoredIndex = 0;
    appDelegate.restoredData = nil;
    appDelegate.startUrl = nil;
    
    [self getIPAddress];
}

- (void)renderTorStatus:(NSString *)statusLine {
    NSRange progress_loc = [statusLine rangeOfString:@"BOOTSTRAP PROGRESS="];
    NSRange progress_r = {
        progress_loc.location + progress_loc.length,
        3
    };
    NSString *progress_str = @"";
    if (progress_loc.location != NSNotFound)
        progress_str = [statusLine substringWithRange:progress_r];
    
    progress_str = [progress_str stringByReplacingOccurrencesOfString:@"%%" withString:@""];
    progress_str = [progress_str stringByReplacingOccurrencesOfString:@" T" withString:@""]; // Remove a T which sometimes appears
    
    NSRange summary_loc = [statusLine rangeOfString:@" SUMMARY="];
    NSString *summary_str = @"";
    if (summary_loc.location != NSNotFound)
        summary_str = [statusLine substringFromIndex:summary_loc.location + summary_loc.length + 1];
    NSRange summary_loc2 = [summary_str rangeOfString:@"\""];
    if (summary_loc2.location != NSNotFound)
        summary_str = [summary_str substringToIndex:summary_loc2.location];
    
    [self performSelectorOnMainThread:@selector(updateTorProgress:) withObject:[NSNumber numberWithFloat:[progress_str intValue]/100.0] waitUntilDone:NO];
    _torProgressDescription.text = [NSString stringWithFormat:@"%@%% - %@", progress_str, summary_str];
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    // Log the progress if it hasn't been logged yet
    if ([appDelegate.logViewController.logTextView.text rangeOfString:[@"[Tor] " stringByAppendingString:_torProgressDescription.text]].location == NSNotFound)
        [appDelegate.logViewController logInfo:[@"[Tor] " stringByAppendingString:_torProgressDescription.text]];
    
    if ([progress_str isEqualToString:@"100"]) {
        [self performSelectorOnMainThread:@selector(removeTorProgressView) withObject:nil waitUntilDone:NO];
    }
}

- (void)displayTorPanel {
    _torPanelView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 300, 120)];
    _torPanelView.center = self.view.center;
    _torPanelView.layer.cornerRadius = 5.0f;
    _torPanelView.layer.masksToBounds = YES;
    _torPanelView.alpha = 0;
    
    _torDarkBackgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    _torDarkBackgroundView.backgroundColor = [UIColor blackColor];
    _torDarkBackgroundView.alpha = 0;
    
    [self.view addSubview:_torDarkBackgroundView];
    [self.view addSubview:_torPanelView];
    
    UILabel *torTitle = [[UILabel alloc] initWithFrame:CGRectMake(0, 10, 300, 30)];
    torTitle.text = NSLocalizedString(@"Tor panel", nil);
    torTitle.font = [UIFont systemFontOfSize:20.0f];
    torTitle.textAlignment = NSTextAlignmentCenter;
    [_torPanelView addSubview:torTitle];
    
    UIButton *closeButton = [[UIButton alloc] initWithFrame:CGRectMake(260, 10, 30, 30)];
    [closeButton setTitle:[NSString stringWithFormat:@"%C", 0x2715] forState:UIControlStateNormal];
    [closeButton.titleLabel setFont:[UIFont systemFontOfSize:25.0f weight:UIFontWeightLight]];
    [closeButton addTarget:self action:@selector(hideTorPanel) forControlEvents:UIControlEventTouchUpInside];
    [_torPanelView addSubview:closeButton];
    
    UIButton *logButton = [[UIButton alloc] initWithFrame:CGRectMake(13, 13, 24, 24)];
    [logButton setImage:[[UIImage imageNamed:@"Log"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [logButton addTarget:self action:@selector(showLog) forControlEvents:UIControlEventTouchUpInside];
    [_torPanelView addSubview:logButton];
    
    UIButton *circuitInfoButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
    [circuitInfoButton setFrame:CGRectMake(closeButton.frame.origin.x, 45, closeButton.frame.size.width, 25)];
    [circuitInfoButton addTarget:self action:@selector(showCircuitInfo) forControlEvents:UIControlEventTouchUpInside];
    [_torPanelView insertSubview:circuitInfoButton belowSubview:closeButton];
    
    _IPAddressLabel = [[UILabel alloc] initWithFrame:CGRectMake(logButton.frame.origin.x, circuitInfoButton.frame.origin.y, 250, circuitInfoButton.frame.size.height)];
    [_IPAddressLabel setAdjustsFontSizeToFitWidth:YES];
    
    _IPAddressLabel.text = NSLocalizedString(@"IP: Loading…", nil);
    [self getIPAddress];
    
    _IPAddressLabel.textAlignment = NSTextAlignmentLeft;
    [_torPanelView addSubview:_IPAddressLabel];
    
    UIButton *newIdentityButton = [[UIButton alloc] initWithFrame:CGRectMake(10, 85, 280, 25)];
    newIdentityButton.titleLabel.numberOfLines = 1;
    newIdentityButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    newIdentityButton.titleLabel.lineBreakMode = NSLineBreakByClipping;
    [newIdentityButton setTitle:NSLocalizedString(@"New identity", nil) forState:UIControlStateNormal];
    [newIdentityButton addTarget:self action:@selector(newIdentity) forControlEvents:UIControlEventTouchUpInside];
    [_torPanelView addSubview:newIdentityButton];
    
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    NSMutableDictionary *settings = appDelegate.getSettings;
    if (![[settings valueForKey:@"night-mode"] boolValue]) {
        _torPanelView.backgroundColor = [UIColor groupTableViewBackgroundColor];
        torTitle.textColor = [UIColor blackColor];
        [closeButton setTitleColor:self.view.tintColor forState:UIControlStateNormal];
        [logButton setTintColor:self.view.tintColor];
        [circuitInfoButton setTintColor:self.view.tintColor];
        _IPAddressLabel.textColor = [UIColor blackColor];
        [newIdentityButton setTitleColor:self.view.tintColor forState:UIControlStateNormal];
    } else {
        _torPanelView.backgroundColor = [UIColor darkGrayColor];
        torTitle.textColor = [UIColor whiteColor];
        [closeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [logButton setTintColor:[UIColor whiteColor]];
        [circuitInfoButton setTintColor:[UIColor whiteColor]];
        _IPAddressLabel.textColor = [UIColor whiteColor];
        [newIdentityButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    }
    
    [self.view bringSubviewToFront:_torDarkBackgroundView];
    [self.view bringSubviewToFront:_torPanelView];
    
    [UIView animateWithDuration:0.3 animations:^{
        self->_torDarkBackgroundView.alpha = 0.5f;
        self->_torPanelView.alpha = 1.0f;
    }];
}

- (void)hideTorPanel {
    [UIView animateWithDuration:0.3 animations:^{
        self->_torDarkBackgroundView.alpha = 0;
        self->_torPanelView.alpha = 0;
    } completion:^(BOOL finished) {
        [self->_torDarkBackgroundView removeFromSuperview];
        [self->_torPanelView removeFromSuperview];
        self->_torDarkBackgroundView = nil;
        self->_torPanelView = nil;
    }];
}

- (void)showLog {
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    CATransition *transition = [CATransition animation];
    transition.duration = 0.3;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionPush;
    transition.subtype = kCATransitionFromRight;
    [self.view.window.layer addAnimation:transition forKey:nil];
    [self presentViewController:appDelegate.logViewController animated:NO completion:nil];
}

- (void)showCircuitInfo {
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    [appDelegate.tor requestTorInfo];

    TorCircuitTableViewController *infoTVC = [[TorCircuitTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:infoTVC];
    [self presentViewController:navigationController animated:YES completion:nil];
}

- (void)showTLSStatus {
    int tlsStatus = [(CustomWebView *)_webViewObject TLSStatus];
    
    if (tlsStatus == TLSSTATUS_HIDDEN) {
        [_addressTextField setLeftViewMode:UITextFieldViewModeNever];
    } else if (tlsStatus == TLSSTATUS_SECURE) {
        [_addressTextField setLeftViewMode:UITextFieldViewModeUnlessEditing];
        [_addressTextField.tlsButton setImage:[[UIImage imageNamed:@"Lock"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    } else {
        [_addressTextField setLeftViewMode:UITextFieldViewModeUnlessEditing];
        [_addressTextField.tlsButton setImage:[[UIImage imageNamed:@"BrokenLock"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    }
}

- (void)getIPAddress {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        int currentIndentityNumber = self->_newIdentityNumber;
        
        NSURL *URL = [[NSURL alloc] initWithString:@"https://api.ipify.org?format=json"];
        NSData *data = [NSData dataWithContentsOfURL:URL options:NSDataReadingUncached error:nil];
        
        if (data) {
            NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
            NSString *IP = [dictionary objectForKey:@"ip"];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (self->_newIdentityNumber == currentIndentityNumber) {
                    if (IP) {
                        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
                        [appDelegate.tor setCurrentVisibleIP:IP];

                        self->_IPAddress = IP;
                        self->_IPAddressLabel.text = [NSString stringWithFormat:NSLocalizedString(@"IP: %@", nil), self->_IPAddress];
                    } else if (self->_newIdentityTryCount < kNewIdentityMaxTries) {
                        self->_newIdentityTryCount += 1;
                        [self getIPAddress]; // Try again
                        self->_IPAddressLabel.text = NSLocalizedString(@"IP: Error, trying again…", nil);
                    } else {
                        self->_IPAddressLabel.text = NSLocalizedString(@"IP: Error", nil);
                    }
                }
            });
        } else if (self->_newIdentityNumber == currentIndentityNumber) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (self->_newIdentityTryCount < kNewIdentityMaxTries) {
                    self->_newIdentityTryCount += 1;
                    [self getIPAddress]; // Try again
                    self->_IPAddressLabel.text = NSLocalizedString(@"IP: Error, trying again…", nil);
                } else {
                    self->_IPAddressLabel.text = NSLocalizedString(@"IP: Error", nil);
                }
            });
        }
    });
    
    dispatch_async(dispatch_get_main_queue(), ^{
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        [appDelegate.tor requestTorInfo];
    });
}


#pragma mark - Target actions

- (void)goBackTapped:(UIBarButtonItem *)sender {
    [_webViewObject stopLoading];
    [_webViewObject goBack];
}

- (void)goForwardTapped:(UIBarButtonItem *)sender {
    [_webViewObject stopLoading];
    [_webViewObject goForward];
}

- (void)refreshTapped:(UIBarButtonItem *)sender {
    [_webViewObject reload];
}

- (void)stopTapped:(UIBarButtonItem *)sender {
    [_webViewObject stopLoading];
    [self updateNavigationItems];
}

- (void)settingsTapped:(UIBarButtonItem *)sender {
    // Increment the rating counter, and show it if the requirements are met
    [[iRate sharedInstance] logEvent:NO];
    [self openSettingsView];
}

- (void)onionTapped:(UIBarButtonItem *)sender {
    [self displayTorPanel];
}

- (void)clearAllTapped:(UIBarButtonItem *)sender {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:NSLocalizedString(@"Close all tabs", nil) otherButtonTitles:nil];
    
    [actionSheet showInView:self.view];
}

- (void)newIdentity {
    _newIdentityNumber ++;
    _newIdentityTryCount = 0;
    _IPAddress = nil;
    _IPAddressLabel.text = NSLocalizedString(@"IP: Loading…", nil);
    
    [UIView animateWithDuration:0.3 animations:^{
        self->_torPanelView.alpha = 0;
    } completion:^(BOOL finished) {
        [self->_torPanelView removeFromSuperview];
        self->_torPanelView = nil;
    }];
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:appDelegate.window animated:YES];
    hud.mode = MBProgressHUDModeIndeterminate;
    [hud.label setNumberOfLines:2];
    hud.label.text = NSLocalizedString(@"Clearing cache…", nil);
    
    for (int i = 0; i < [[self contentViews] count]; i++) {
        [[[self contentViews] objectAtIndex:i] stopLoading];
    }

    [appDelegate wipeAppData];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [appDelegate.tor requestNewTorIdentity];
        hud.label.text = NSLocalizedString(@"Requesting new identity…", nil);
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(7.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [appDelegate wipeAppData];

            for (int i = 0; i < [[self contentViews] count]; i++) {
                if (i != self.currentIndex)
                    [[[self contentViews] objectAtIndex:i] setNeedsForceRefresh:YES];
                else
                    [[[self contentViews] objectAtIndex:i] reload];
            }
            
            [hud hideAnimated:YES];
            
            [UIView animateWithDuration:0.3 animations:^{
                self->_torDarkBackgroundView.alpha = 0;
            } completion:^(BOOL finished) {
                [self->_torDarkBackgroundView removeFromSuperview];
                self->_torDarkBackgroundView = nil;
                [self getIPAddress];
            }];
        });
    });
}

-(void)openSettingsView {
    SettingsTableViewController *settingsController = [[SettingsTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
    UINavigationController *settingsNavController = [[UINavigationController alloc]
                                                     initWithRootViewController:settingsController];
    
    [self presentViewController:settingsNavController animated:YES completion:nil];
}


#pragma mark - Action sheet delegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == actionSheet.cancelButtonIndex)
        return;
    else if (buttonIndex == actionSheet.destructiveButtonIndex) {
        [self closeAllTabs];
    }
}


#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if ((alertView.tag == ALERTVIEW_TORFAIL) && (buttonIndex == 1)) {
        // Tor failed, user says we can quit app.
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        [appDelegate wipeAppData];
        exit(0);
    }
    
    if ((alertView.tag == ALERTVIEW_EXTERN_PROTO)) {
        if (buttonIndex == 1) {
            // Warned user about opening URL in external app and they said it's OK.
            NSURL *navigationURL = objc_getAssociatedObject(alertView, &AlertViewExternProtoUrl);
            [[UIApplication sharedApplication] openURL:navigationURL];
        }
    } else if ((alertView.tag == ALERTVIEW_INCOMING_URL)) {
        if (buttonIndex == 1) {
            // Warned user about opening this incoming URL and they said it's OK.
            NSURL *navigationURL = objc_getAssociatedObject(alertView, &AlertViewIncomingUrl);
            [self addNewTabForURL:navigationURL];
        }
    }
}


#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    [self.navBar showCancelButton];
    _addressTextField.textAlignment = NSTextAlignmentLeft;
    
    // Get current selected range , this example assumes is an insertion point or empty selection
    UITextRange *selectedRange = [textField selectedTextRange];
    
    // Calculate the new position, - for left and + for right
    UITextPosition *newPosition = [textField positionFromPosition:selectedRange.start offset:-textField.text.length];
    
    // Construct a new range using the object that adopts the UITextInput, our textfield
    UITextRange *newRange = [textField textRangeFromPosition:newPosition toPosition:selectedRange.start];
    
    // Set new range
    [textField setSelectedTextRange:newRange];
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if (_bookmarks == nil) {
        _bookmarks = [[BookmarkTableViewController alloc] init];
        
        NSManagedObjectContext *context = [appDelegate managedObjectContext];
        _bookmarks.managedObjectContext = context;
        
        _bookmarks.view.frame = CGRectMake(0, [[UIApplication sharedApplication] statusBarFrame].size.height + 44, self.view.frame.size.width, self.view.frame.size.height - ([[UIApplication sharedApplication] statusBarFrame].size.height + 44));
    }
    
    NSMutableDictionary *settings = appDelegate.getSettings;
    if (![[settings valueForKey:@"night-mode"] boolValue])
        [_bookmarks setLightMode];
    else
        [_bookmarks setDarkMode];
    
    [_bookmarks setEmbedded:YES];
    
    [UIView animateWithDuration:kNavigationBarAnimationTime animations:^{
        [self.view addSubview:self->_bookmarks.tableView];
    }];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    
    // Search if necessary
    NSString *urlString = [self isURL:textField.text];
    if (urlString) {
        if ([urlString hasPrefix:@"https"])
            [(CustomWebView *)_webViewObject updateTLSStatus:TLSSTATUS_SECURE];
        else
            [(CustomWebView *)_webViewObject updateTLSStatus:TLSSTATUS_INSECURE];
        
        NSURL *url = [NSURL URLWithString:urlString];
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        [_webViewObject loadRequest:request];
    } else if (textField.text.length > 0) {
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        NSMutableDictionary *settings = appDelegate.getSettings;

        /*
        BOOL javascriptEnabled = true;
        NSInteger js_setting = [[settings valueForKey:@"javascript-toggle"] integerValue];
        NSInteger csp_setting = [[settings valueForKey:@"javascript"] integerValue];
        
        if (csp_setting == CONTENTPOLICY_STRICT || js_setting == JS_BLOCKED)
            javascriptEnabled = false;
        */
        
        NSString *searchEngine = [settings valueForKey:@"search-engine"];
        NSDictionary *searchEngineURLs = [NSMutableDictionary dictionaryWithContentsOfFile:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"searchEngineURLs.plist"]];
        
        /*
        if (javascriptEnabled)
            urlString = [[NSString stringWithFormat:[[searchEngineURLs objectForKey:searchEngine] objectForKey:@"search"], textField.text] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        else
            urlString = [[NSString stringWithFormat:[[searchEngineURLs objectForKey:searchEngine] objectForKey:@"search_no_js"], textField.text] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        */
        urlString = [[NSString stringWithFormat:[[searchEngineURLs objectForKey:searchEngine] objectForKey:@"search_no_js"], textField.text] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        if ([urlString hasPrefix:@"https"])
            [(CustomWebView *)_webViewObject updateTLSStatus:TLSSTATUS_SECURE];
        else
            [(CustomWebView *)_webViewObject updateTLSStatus:TLSSTATUS_INSECURE];
        
        NSURL *url = [NSURL URLWithString:urlString];
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        [_webViewObject loadRequest:request];
    } else {
        [(CustomWebView *)_webViewObject updateTLSStatus:TLSSTATUS_HIDDEN];
    }
    
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [self.navBar hideCancelButton];
    
    UIButton *refreshStopButton = _webViewObject.isLoading ? _addressTextField.stopButton : _addressTextField.refreshButton;
    refreshStopButton.alpha = textField.text.length > 0;
    
    [UIView animateWithDuration:kNavigationBarAnimationTime animations:^{
        [self->_bookmarks.tableView removeFromSuperview];
    }];
}


#pragma mark - MTPageView methods

- (BOOL)canAddTab {
    return self.tabsCount < 99;
}

- (MTPageViewTab *)newTabAtIndex:(int)index withTitle:(NSString *)title {
    // Override this to use a custom tab
    MTPageViewTab *newTab = [super newTabAtIndex:index withTitle:title];
    
    if (!title) {
        [newTab setTitle:NSLocalizedString(@"New tab", nil)];
    }

    CustomWebView *webView = [[CustomWebView alloc] initWithFrame:self.view.bounds];
    [webView setCenter:newTab.center];
    [webView setParent:self];
    [webView.scrollView setScrollsToTop:NO];
    [newTab addSubview:webView];
    
    MTScrollBarManager *scrollBarManager = [[MTScrollBarManager alloc] initWithNavBar:self.navBar andToolBar:self.selectedToolbar andScrollView:webView.scrollView];
    [newTab setScrollBarManager:scrollBarManager];
    
    [self.contentViews insertObject:webView atIndex:index];

    return newTab;
}


#pragma mark - MTPageView events

- (void)didMoveTabAtIndex:(int)fromIndex toIndex:(int)toIndex {
    CustomWebView *contentView = [self.contentViews objectAtIndex:fromIndex];
    [self.contentViews removeObjectAtIndex:fromIndex];
    
    int newIndex = toIndex;
    if (fromIndex < toIndex) {
        // Removed an object before toIndex, so actually insert at toIndex - 1
        newIndex -= 1;
    }
    
    [self.contentViews insertObject:contentView atIndex:newIndex];
}

- (void)didCloseTabAtIndex:(int)index {
    [[self.contentViews objectAtIndex:index] stopLoading];
    [self.contentViews removeObjectAtIndex:index];
}

- (void)tabsWillBecomeVisible {
    for (CustomWebView *webView in self.contentViews) {
        [webView.scrollView setShowsVerticalScrollIndicator:NO];
        [webView.scrollView setShowsHorizontalScrollIndicator:NO];
    }
    
    [_webViewObject.scrollView setScrollsToTop:NO];
    self.navBar.progressView.hidden = YES;
}

- (void)tabsWillBecomeHidden {
    if ([self.contentViews count] > self.currentIndex) {
        _webViewObject = [self.contentViews objectAtIndex:self.currentIndex];
        NSURL *url = [(CustomWebView *)_webViewObject url];
        
        NSString *urlProto = [[url scheme] lowercaseString];
        if ([urlProto isEqualToString:@"https"]) {
            [(CustomWebView *)_webViewObject updateTLSStatus:TLSSTATUS_SECURE];
        } else if (urlProto && ![urlProto isEqualToString:@""]) {
            [(CustomWebView *)_webViewObject updateTLSStatus:TLSSTATUS_INSECURE];
        } else {
            [(CustomWebView *)_webViewObject updateTLSStatus:TLSSTATUS_HIDDEN];
        }

        [self.navBar.textField setText:[url absoluteString]];
        
        UIButton *refreshStopButton = _webViewObject.isLoading ? _addressTextField.stopButton : _addressTextField.refreshButton;
        refreshStopButton.alpha = _addressTextField.text.length > 0;
    }
}

- (void)tabsDidBecomeHidden {
    if (self.currentIndex >= [self.contentViews count]) {
        return;
    }
    
    [[[self.contentViews objectAtIndex:self.currentIndex] scrollView] setShowsVerticalScrollIndicator:YES];
    [[[self.contentViews objectAtIndex:self.currentIndex] scrollView] setShowsHorizontalScrollIndicator:YES];
    [[[self.contentViews objectAtIndex:self.currentIndex] scrollView] flashScrollIndicators];
    
    _webViewObject = [self.contentViews objectAtIndex:self.currentIndex];
    self.navBar.progressView.hidden = NO;
    [_webViewObject.scrollView setScrollsToTop:YES];
    [self.navBar.progressView setProgress:[(CustomWebView *)_webViewObject progress]];
    [self.navBar.textField setText:[[(CustomWebView *)_webViewObject url] absoluteString]];
    
    UIButton *refreshStopButton = _webViewObject.isLoading ? _addressTextField.stopButton : _addressTextField.refreshButton;
    _addressTextField.rightView = refreshStopButton;
    
    if ([(CustomWebView *)_webViewObject progress] == 1.0f) {
        self.navBar.progressView.alpha = 0.0f; // Done loading for this page, don't show the progress
    } else {
        self.navBar.progressView.alpha = 1.0f;
    }
    
    if ([[_addressTextField text] isEqualToString:@""] && ![_webViewObject isLoading]) {
        if (!_torLoadingView) {
            [_addressTextField becomeFirstResponder];
        }
        self.navBar.progressView.alpha = 0.0f;
    }
    
    NSURL *url = [(CustomWebView *)_webViewObject url];
    
    NSString *urlProto = [[url scheme] lowercaseString];
    if ([urlProto isEqualToString:@"https"]) {
        [(CustomWebView *)_webViewObject updateTLSStatus:TLSSTATUS_SECURE];
    } else if (urlProto && ![urlProto isEqualToString:@""]) {
        [(CustomWebView *)_webViewObject updateTLSStatus:TLSSTATUS_INSECURE];
    } else {
        [(CustomWebView *)_webViewObject updateTLSStatus:TLSSTATUS_HIDDEN];
    }
    [self.navBar.textField setText:[url absoluteString]];
    
    if ([(CustomWebView *)_webViewObject needsForceRefresh]) {
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        [_webViewObject loadRequest:request];
        [(CustomWebView *)_webViewObject setNeedsForceRefresh:NO];
        
        UIButton *refreshStopButton = _webViewObject.isLoading ? _addressTextField.stopButton : _addressTextField.refreshButton;
        refreshStopButton.alpha = _addressTextField.text.length > 0;
    }
}

- (void)didBeginSwitchingTabAtIndex:(int)index {
    for (CustomWebView *webView in self.contentViews) {
        [webView.scrollView.pinchGestureRecognizer setEnabled:NO];
        [webView.scrollView.panGestureRecognizer setEnabled:NO];
    }
    
    [self tabsWillBecomeVisible];
}

- (void)didCancelSwitchingTabAtIndex:(int)index {
    for (CustomWebView *webView in self.contentViews) {
        [webView.scrollView.pinchGestureRecognizer setEnabled:YES];
        [webView.scrollView.panGestureRecognizer setEnabled:YES];
    }
}

- (void)didFinishSwitchingTabAtIndex:(int)fromIndex toIndex:(int)toIndex {
    for (CustomWebView *webView in self.contentViews) {
        [webView.scrollView.pinchGestureRecognizer setEnabled:YES];
        [webView.scrollView.panGestureRecognizer setEnabled:YES];
    }
    
    [self tabsDidBecomeHidden];
}

@end
