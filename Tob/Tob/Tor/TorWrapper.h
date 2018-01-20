// Copyright © 2012-2016 Mike Tigas
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <Foundation/Foundation.h>
#import <Tor/Tor.h>

@interface TorWrapper : NSObject
@property (nonatomic, retain) TORThread *tor;

//-(NSData *)readTorCookie;
-(void)start;
@end
