//
//  ViewController.h
//  Tob
//
//  Created by Jean-Romain on 26/04/2016.
//  Copyright © 2016 JustKodding. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MTPageViewController.h"
#import "CustomWebView.h"

@class CustomWebView;

#define TLSSTATUS_HIDDEN 0
#define TLSSTATUS_SECURE 1
#define TLSSTATUS_INSECURE 2

extern const char AlertViewExternProtoUrl;
extern const char AlertViewIncomingUrl;

@interface TabsViewController : MTPageViewController <UITextFieldDelegate, UIActionSheetDelegate>

@property (nonatomic, strong) NSString *IPAddress;
@property (nonatomic) int newIdentityNumber; // An integer containing the current identity number, to avoid showing the wrong IP


- (NSMutableArray<CustomWebView *> *)contentViews;

- (void)loadURL:(NSURL *)url;
- (void)askToLoadURL:(NSURL *)url;
- (void)addNewTabForURL:(NSURL *)url;
- (void)stopLoading;
- (void)refreshCurrentTab;
- (void)setTabsNeedForceRefresh:(BOOL)needsForceRefresh;

- (void)updateNavigationItems;
- (void)updateProgress:(float)progress animated:(BOOL)animated;
- (void)hideProgressBarAnimated:(BOOL)animated;
- (void)showProgressBarAnimated:(BOOL)animated;

- (void)renderTorStatus:(NSString *)statusLine;
- (void)showTLSStatus;

- (void)saveAppState;
- (void)getRestorableData;

@end
