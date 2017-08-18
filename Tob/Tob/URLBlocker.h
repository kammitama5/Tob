//
//  URLBlocker.h
//  Tob
//
//  Created by Jean-Romain on 17/08/2017.
//  Copyright © 2017 JustKodding. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface URLBlocker : NSObject

+ (NSDictionary *)blockers;
+ (NSMutableArray *)disabledBlockers;
+ (NSMutableArray *)whitelistedDomains;

+ (NSString *)ruleForURL:(NSURL *)URL andMainDocumentURL:(NSURL *)mainDocumentURL;
+ (BOOL)shouldBlockURL:(NSURL *)URL withMainDocumentURL:(NSURL *)mainDocumentURL;

+ (void)disableBlockerForHost:(NSString *)host;
+ (void)temporarilyDisableBlockerForHost:(NSString *)host;
+ (void)enableBlockerForHost:(NSString *)host;

+ (void)addDomainToWhitelist:(NSString *)domain;
+ (void)removeDomainFromWhitelist:(NSString *)domain;

@end
