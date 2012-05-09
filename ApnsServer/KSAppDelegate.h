//
//  KSAppDelegate.h
//  ApnsServer
//
//  Created by Jinbo He on 12-5-8.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ioSock.h"


@interface KSAppDelegate : NSObject <NSApplicationDelegate,NSTableViewDelegate,NSTableViewDataSource> {

    NSString *_deviceToken, *_payload, *_certificate;
    otSocket socket;
    SSLContextRef context;
    SecKeychainRef keychain;
    SecCertificateRef certificate;
    SecIdentityRef identity;
    
    IBOutlet NSTextField        *_txtAlertBody;
    IBOutlet NSTextField        *_txtBadgeNumber;
    IBOutlet NSTableView        *_tableView;
    NSString                    *soundName;
    
    NSMutableArray              *_devices;
}

@property(assign) IBOutlet NSWindow *window;
@property(retain) NSString  *soundName;

- (IBAction)pushNotify:(id)sender;
- (IBAction)doSelectSound:(id)sender;

@end
