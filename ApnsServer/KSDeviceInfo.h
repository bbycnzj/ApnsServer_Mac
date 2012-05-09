//
//  KSDeviceInfo.h
//  ApnsServer
//
//  Created by Jinbo He on 12-5-8.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//


@interface KSDeviceInfo : NSObject {
    NSString    *name;
    NSString    *token;
    NSInteger   state;
}

@property(retain) NSString *name;
@property(retain) NSString *token;
@property(assign) NSInteger state;

@end
