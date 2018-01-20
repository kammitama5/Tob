//
//  URLBlocker.m
//  Tob
//
//  Created by Jean-Romain on 17/08/2017.
//  Copyright © 2017 JustKodding. All rights reserved.
//

#import "URLBlocker.h"

@implementation URLBlocker

static NSDictionary *_blockers;
static NSMutableArray *_disabledBlockers;
static NSMutableArray *_whitelistedDomains;
static NSCache *blockersCache;

#define CACHE_SIZE 50

#pragma mark - Lazy load

+ (NSDictionary *)blockers {
    if (!_blockers) {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"blockerlist" ofType:@"json"];
        
        NSError *error;
        NSString *fileContents = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
        
        if (error) {
            _blockers = [[NSDictionary alloc] init];
        } else {
            _blockers = (NSDictionary *)[NSJSONSerialization JSONObjectWithData:[fileContents dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
        }
    }
    
    return _blockers;
}

+ (NSMutableArray *)disabledBlockers {
    if (!_disabledBlockers) {
        NSString *path = [URLBlocker pathForDisabledBlockersList];

        NSError *error;
        NSString *fileContents = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
        
        if (error) {
            // File is missing, create it
#ifdef DEBUG
            NSLog(@"[URLBlocker] disabledblockerlist.json not found, creating it ");
#endif
            _disabledBlockers = [[NSMutableArray alloc] init];
            [self writeToDisabledBlockersListWithArray:_disabledBlockers];
        } else {
            _disabledBlockers = [[NSMutableArray alloc] initWithArray:[NSJSONSerialization JSONObjectWithData:[fileContents dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil]];
        }
    }
    
    return _disabledBlockers;
}

+ (NSMutableArray *)whitelistedDomains {
    if (!_whitelistedDomains) {
        NSString *path = [URLBlocker pathForWhitelist];
        
        NSError *error;
        NSString *fileContents = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
        
        if (error) {
            // File is missing, create it
#ifdef DEBUG
            NSLog(@"[URLBlocker] blockerwhitelist.json not found, creating it ");
#endif
            _whitelistedDomains = [[NSMutableArray alloc] init];
            [self writeToWhitelistWithArray:_whitelistedDomains];
        } else {
            _whitelistedDomains = [[NSMutableArray alloc] initWithArray:[NSJSONSerialization JSONObjectWithData:[fileContents dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil]];
        }
    }
    
    return _whitelistedDomains;
}


#pragma mark - Private methods

+ (void)cacheRule:(NSString *)rule forURL:(NSURL *)URL {
    if (!blockersCache) {
        blockersCache = [[NSCache alloc] init];
        [blockersCache setCountLimit:CACHE_SIZE];
    }
    
    [blockersCache setObject:rule forKey:URL];
}

+ (NSString *)pathForDisabledBlockersList {
    NSString *filePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *fileName = @"disabledblockerlist.json";

    return [filePath stringByAppendingPathComponent:fileName];
}

+ (void)writeToDisabledBlockersListWithArray:(NSArray *)array {
    NSString *path = [URLBlocker pathForDisabledBlockersList];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [[NSFileManager defaultManager] createFileAtPath:path contents:nil attributes:nil];
    }
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:array options:0 error:nil];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];

    [[jsonString dataUsingEncoding:NSUTF8StringEncoding] writeToFile:path atomically:NO];
}

+ (NSString *)pathForWhitelist {
    NSString *filePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *fileName = @"blockerwhitelist.json";
    
    return [filePath stringByAppendingPathComponent:fileName];
}

+ (void)writeToWhitelistWithArray:(NSArray *)array {
    NSString *path = [URLBlocker pathForWhitelist];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [[NSFileManager defaultManager] createFileAtPath:path contents:nil attributes:nil];
    }
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:array options:0 error:nil];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    [[jsonString dataUsingEncoding:NSUTF8StringEncoding] writeToFile:path atomically:NO];
}


#pragma mark - Public methods

+ (NSString *)ruleForURL:(NSURL *)URL andMainDocumentURL:(NSURL *)mainDocumentURL {
    // Find out if the main document's domain is whitelisted
    // Try out all possible "sub-domains"
    NSArray *domainParts = [[[mainDocumentURL host] lowercaseString] componentsSeparatedByString:@"."];
    
    if (domainParts.count > 1) {
        // No need to try the last element as it will just be ".com", ".net"...
        for (int i = 0; i < [domainParts count] - 1; i++) {
            NSString *testDomain = [[domainParts subarrayWithRange:NSMakeRange(i, [domainParts count] - i)] componentsJoinedByString:@"."];
            
            if ([[URLBlocker whitelistedDomains] containsObject:testDomain]) {
                // This domain is whitelisted, ignore all rule (but don't cache anything in case it changes)
#ifdef DEBUG
                NSLog(@"[URLBlocker] Ignoring rules for whitelisted domain %@", testDomain);
#endif
                return nil;
            }
        }
    }
    
    NSString *host = [[URL host] lowercaseString];
    NSString *rule = @" "; // Start with a non-nil rule that matches no url to cache it if the URL has no matching rule
    NSString *matchedHost = host;
    
    if (blockersCache && [blockersCache objectForKey:URL]) {
        // The rule for this url is cached, check if the url matches the rule
        NSString *testRule = [blockersCache objectForKey:URL];
        NSRange searchedRange = NSMakeRange(0, [[URL absoluteString] length]);
        NSError *error = nil;
        
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:testRule options:0 error:&error];
        NSArray *matches = [regex matchesInString:[URL absoluteString] options:0 range:searchedRange];
        
        if ([matches count] > 0) {
            rule = testRule;
        }
    } else {
        // Try out all possible "sub-hosts"
        NSArray *hostParts = [host componentsSeparatedByString:@"."];

        // No need to try the last element as it will just be ".com", ".net"...
        for (int i = 0; i < [hostParts count] - 1; i++) {
            NSString *testHost = [[hostParts subarrayWithRange:NSMakeRange(i, [hostParts count] - i)] componentsJoinedByString:@"."];

            if ([[URLBlocker blockers] objectForKey:testHost]) {
                // Found the correct rule, check if the URL matches the rule
                matchedHost = testHost;
                NSString *testRule = [[URLBlocker blockers] objectForKey:testHost];
                
                NSRange searchedRange = NSMakeRange(0, [[URL absoluteString] length]);
                NSError *error = nil;
                
                NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:testRule options:0 error:&error];
                NSArray *matches = [regex matchesInString:[URL absoluteString] options:0 range:searchedRange];
                
                if ([matches count] > 0) {
                    rule = testRule;
                }
                
                break;
            }
        }
    }
    
    // If the rule for this host is disabled, ignore it (but don't cache it in case it changes)
    if ([[URLBlocker disabledBlockers] containsObject:matchedHost]) {
#ifdef DEBUG
        NSLog(@"[URLBlocker] Ignoring rule for %@", matchedHost);
#endif
        return nil;
    }
    
    // Cache the rule that was found (even if it's empty)
    [URLBlocker cacheRule:rule forURL:URL];
    
    return [rule isEqualToString:@" "] ? nil: rule;
}

+ (BOOL)shouldBlockURL:(NSURL *)URL withMainDocumentURL:(NSURL *)mainDocumentURL {
    return [URLBlocker ruleForURL:URL andMainDocumentURL:mainDocumentURL] != nil;
}

+ (void)disableBlockerForHost:(NSString *)host {
    if (![[URLBlocker disabledBlockers] containsObject:[host lowercaseString]])
        [[URLBlocker disabledBlockers] addObject:[host lowercaseString]];
    
    NSString *path = [URLBlocker pathForDisabledBlockersList];
    
    NSError *error;
    NSString *fileContents = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
    NSMutableArray *disabledBlockers;
    
    if (error) {
        disabledBlockers = [[NSMutableArray alloc] init];
    } else {
        disabledBlockers = [[NSMutableArray alloc] initWithArray:[NSJSONSerialization JSONObjectWithData:[fileContents dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil]];
    }
    
    if (![disabledBlockers containsObject:[host lowercaseString]]) {
        [disabledBlockers addObject:[host lowercaseString]];
        [self writeToDisabledBlockersListWithArray:disabledBlockers];
    }
}

+ (void)temporarilyDisableBlockerForHost:(NSString *)host {
    [[URLBlocker disabledBlockers] addObject:[host lowercaseString]];
}

+ (void)enableBlockerForHost:(NSString *)host {
    if ([[URLBlocker disabledBlockers] containsObject:[host lowercaseString]]) {
        [[URLBlocker disabledBlockers] removeObject:[host lowercaseString]];
        
        NSString *path = [URLBlocker pathForDisabledBlockersList];
        
        NSError *error;
        NSString *fileContents = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
        NSMutableArray *disabledBlockers;
        
        if (error) {
            disabledBlockers = [[NSMutableArray alloc] init];
        } else {
            disabledBlockers = [[NSMutableArray alloc] initWithArray:[NSJSONSerialization JSONObjectWithData:[fileContents dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil]];
        }
        
        if ([disabledBlockers containsObject:[host lowercaseString]]) {
            [disabledBlockers removeObject:[host lowercaseString]];
            [self writeToDisabledBlockersListWithArray:disabledBlockers];
        }
    }
}

+ (void)addDomainToWhitelist:(NSString *)domain; {
    if ([domain hasPrefix:@"www."]) {
        if (domain.length > 4) {
            domain = [domain substringFromIndex:4];
        } else {
            return;
        }
    }
    
    if (![[URLBlocker whitelistedDomains] containsObject:[domain lowercaseString]])
        [[URLBlocker whitelistedDomains] addObject:[domain lowercaseString]];
    
    NSString *path = [URLBlocker pathForWhitelist];
    
    NSError *error;
    NSString *fileContents = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
    NSMutableArray *whitelistedDomains;
    
    if (error) {
        whitelistedDomains = [[NSMutableArray alloc] init];
    } else {
        whitelistedDomains = [[NSMutableArray alloc] initWithArray:[NSJSONSerialization JSONObjectWithData:[fileContents dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil]];
    }
    
    if (![whitelistedDomains containsObject:[domain lowercaseString]]) {
        [whitelistedDomains addObject:[domain lowercaseString]];
        [self writeToWhitelistWithArray:whitelistedDomains];
    }
}

+ (void)removeDomainFromWhitelist:(NSString *)domain; {    
    if ([[URLBlocker whitelistedDomains] containsObject:[domain lowercaseString]]) {
        [[URLBlocker whitelistedDomains] removeObject:[domain lowercaseString]];
        
        NSString *path = [URLBlocker pathForWhitelist];
        
        NSError *error;
        NSString *fileContents = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
        NSMutableArray *whitelistedDomains;
        
        if (error) {
            whitelistedDomains = [[NSMutableArray alloc] init];
        } else {
            whitelistedDomains = [[NSMutableArray alloc] initWithArray:[NSJSONSerialization JSONObjectWithData:[fileContents dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil]];
        }
        
        if ([whitelistedDomains containsObject:[domain lowercaseString]]) {
            [whitelistedDomains removeObject:[domain lowercaseString]];
            [self writeToWhitelistWithArray:whitelistedDomains];
        }
    }
}

@end
