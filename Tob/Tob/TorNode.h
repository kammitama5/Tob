//
//  TorNode.h
//  Tob
//
//  Created by Jean-Romain on 15/08/2017.
//  Copyright © 2017 JustKodding. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TorNode : NSObject

@property (nonatomic, strong) NSString *ID;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *IP;
@property (nonatomic, strong) NSString *country;
@property (nonatomic, strong) NSString *version;
@property (nonatomic, strong) NSNumber *bandwidth;

@end
