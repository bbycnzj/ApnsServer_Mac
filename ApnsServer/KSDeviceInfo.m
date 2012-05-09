//
//  KSDeviceInfo.m
//  ApnsServer
//
//  Created by Jinbo He on 12-5-8.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "KSDeviceInfo.h"

@implementation KSDeviceInfo

@synthesize state,name,token;

- (id)init
{
    self.name = nil;
    self.token = nil;
    
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
