//
//  AppDelegate.h
//  Tob
//
//  Created by Jean-Romain on 26/04/2016.
//  Copyright © 2016 JustKodding. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TabsViewController.h"
#import "TorController.h"
#import "LogViewController.h"
#import "ObfsWrapper.h"

#define COOKIES_ALLOW_ALL 0
#define COOKIES_BLOCK_THIRDPARTY 1
#define COOKIES_BLOCK_ALL 2

// Sets "Content-Security-Policy" headers. See ProxyURLController.m
#define CONTENTPOLICY_STRICT 0 // Blocks nearly every CSP type
#define CONTENTPOLICY_BLOCK_CONNECT 1 // Blocks `connect-src` (XHR, CORS, WebSocket)
#define CONTENTPOLICY_PERMISSIVE 2 // Allows all content (DANGEROUS: websockets leak outside tor)

#define UA_SPOOF_UNSET 0
#define UA_SPOOF_WIN7_TORBROWSER 1
#define UA_SPOOF_SAFARI_MAC 2
#define UA_SPOOF_IPHONE 3
#define UA_SPOOF_IPAD 4
#define UA_SPOOF_NO 5

#define DNT_HEADER_CANTRACK 0
#define DNT_HEADER_NOTRACK 1

#define JS_NO_PREFERENCE 0
#define JS_BLOCKED 1

#define X_DEVICE_IS_IPHONE 0
#define X_DEVICE_IS_IPAD 1
#define X_DEVICE_IS_SIM 2

#define X_TLSVER_ANY 0
#define X_TLSVER_TLS1 1
#define X_TLSVER_TLS1_2_ONLY 2

#define TOR_BRIDGES_NONE 0
#define TOR_BRIDGES_OBFS4 1
#define TOR_BRIDGES_MEEKAMAZON 2
#define TOR_BRIDGES_MEEKAZURE 3
#define TOR_BRIDGES_CUSTOM 99

#define OB_IPV4V6_AUTO 0
#define OB_IPV4V6_V4ONLY 1
#define OB_IPV4V6_V6ONLY 2

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) UIImageView *windowOverlay;

@property (strong, nonatomic) TabsViewController *tabsViewController;
@property (strong, nonatomic) LogViewController *logViewController;
@property (strong, nonatomic) TorController *tor;
@property (strong, nonatomic) ObfsWrapper *obfsproxy;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;

// either nil (to load regular homepage) or url given by a "tob://" (HTTP)
// or "tobs://" (HTTPS) callback url -- when this app is started from another app
@property (nonatomic) NSURL *startUrl;

// list for known domains w/self-signed certs
@property (nonatomic) NSMutableArray *sslWhitelistedDomains;

@property (nonatomic) Boolean doPrepopulateBookmarks;

@property (nonatomic) Boolean usingObfs;
@property (nonatomic) Boolean didLaunchObfsProxy;

@property (nonatomic) NSArray *restoredData;
@property (nonatomic) int restoredIndex;

- (void)recheckObfsproxy;
- (NSUInteger) numBridgesConfigured;
- (void)updateTorrc;
- (NSURL *)applicationLibraryDirectory;
- (NSURL *)applicationDocumentsDirectory;
- (void)clearCookies;
- (void)wipeAppData;
- (NSUInteger) deviceType;
- (Boolean) isRunningTests;

- (NSString *)settingsFile;
- (NSMutableDictionary *)getSettings;
- (void)saveSettings:(NSMutableDictionary *)settings;
- (NSString *)homepage;

- (void)updateFileEncryption;

- (NSString *)javascriptInjection;
- (NSString *)customUserAgent;


@end

