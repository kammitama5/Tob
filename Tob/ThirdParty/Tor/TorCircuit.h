//
//  TorCircuit.h
//  Tob
//
//  Created by Jean-Romain on 15/08/2017.
//  Copyright © 2017 JustKodding. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TorNode.h"

@interface TorCircuit : NSObject

@property (nonatomic, strong) NSMutableArray<TorNode *> *nodes;
@property (nonatomic, strong) NSNumber *ID;
@property (nonatomic, strong) NSArray<NSString*> *buildFlags;
@property (nonatomic, strong) NSString *purpose;
@property (nonatomic, strong) NSDate *timeCreated;

@end
