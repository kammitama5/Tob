//
//  TorNode.m
//  Tob
//
//  Created by Jean-Romain on 15/08/2017.
//  Copyright © 2017 JustKodding. All rights reserved.
//

#import "TorNode.h"

@implementation TorNode

- (NSString *)ID {
    if (_ID)
        return _ID;
    
    return @"?";
}

- (NSString *)name {
    if (_name)
        return _name;
    
    return @"?";
}

- (NSString *)IP {
    if (_IP)
        return _IP;
    
    return @"?";
}

- (NSString *)country {
    if (_country)
        return _country;
    
    return @"?";
}

- (NSString *)version {
    if (_version)
        return _version;
    
    return @"?";
}

@end
