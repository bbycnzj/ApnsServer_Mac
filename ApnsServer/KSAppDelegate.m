//
//  KSAppDelegate.m
//  ApnsServer
//
//  Created by Jinbo He on 12-5-8.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "KSAppDelegate.h"
#import "KSDeviceInfo.h"


@interface KSAppDelegate ()

@property(nonatomic, retain) NSString *deviceToken, *payload, *certificate;
 
- (void)connect;
- (void)disconnect;

@end


@implementation KSAppDelegate

@synthesize window = _window;
@synthesize certificate = _certificate;
@synthesize deviceToken = _deviceToken;
@synthesize payload = _payload;
@synthesize soundName;

- (void)dealloc
{
    self.window=nil;
    self.certificate= nil;
    self.deviceToken=nil;
    self.payload=nil;
    self.soundName=nil;
    [super dealloc];
}

- (id)init
{
    self=[super init];
    
    if (self) {
        self.certificate = [[NSBundle mainBundle] pathForResource:@"apns" ofType:@"cer"];
        self.soundName = @"Drip1.caf";
        _devices = [[NSMutableArray alloc] init];
        
        NSString *file = [[NSBundle mainBundle] pathForResource:@"Device" ofType:@"plist"];
        NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:file];
        
        for (NSDictionary *dictInfo in [dict objectForKey:@"Devices"]) {
            KSDeviceInfo *device = [[KSDeviceInfo alloc] init];
            
            device.name = [dictInfo objectForKey:@"DeviceName"];
            device.state = 0;
            device.token = [dictInfo objectForKey:@"DeviceToken"];;
            
            [_devices addObject:device];
            [device release];
        }
    }
    
    return self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    _txtAlertBody.stringValue = @"该设备正在被查找，请将该设备归还！";
    _txtBadgeNumber.stringValue = @"1";
    [self connect];
}

- (void)applicationWillTerminate:(NSNotification *)notification {
	[self disconnect];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)application {
	return YES;
}


#pragma mark Private

- (void)connect {
	
	if(self.certificate == nil) {
		return;
	}
	
	// Define result variable.
	OSStatus result;
	
	// Establish connection to server.
	PeerSpec peer;
	result = MakeServerConnection("gateway.sandbox.push.apple.com", 2195, &socket, &peer);
	NSLog(@"MakeServerConnection(): %d", result);
	
	// Create new SSL context.
	result = SSLNewContext(false, &context);
	NSLog(@"SSLNewContext(): %d", result);
	
	// Set callback functions for SSL context.
	result = SSLSetIOFuncs(context, SocketRead, SocketWrite);
	NSLog(@"SSLSetIOFuncs(): %d", result);
	
	// Set SSL context connection.
	result = SSLSetConnection(context, socket);
	NSLog(@"SSLSetConnection(): %d", result);
	
	// Set server domain name.
	result = SSLSetPeerDomainName(context, "gateway.sandbox.push.apple.com", 30);
	NSLog(@"SSLSetPeerDomainName(): %d", result);
	
	// Open keychain.
	result = SecKeychainCopyDefault(&keychain);
	NSLog(@"SecKeychainOpen(): %d", result);
	
	// Create certificate.
	NSData *certificateData = [NSData dataWithContentsOfFile:self.certificate];
	CSSM_DATA data;
	data.Data = (uint8 *)[certificateData bytes];
	data.Length = [certificateData length];
	result = SecCertificateCreateFromData(&data, CSSM_CERT_X_509v3, CSSM_CERT_ENCODING_BER, &certificate);
	NSLog(@"SecCertificateCreateFromData(): %d", result);
	
	// Create identity.
	result = SecIdentityCreateWithCertificate(keychain, certificate, &identity);
	NSLog(@"SecIdentityCreateWithCertificate(): %d", result);
	
	// Set client certificate.
	CFArrayRef certificates = CFArrayCreate(NULL, (const void **)&identity, 1, NULL);
	result = SSLSetCertificate(context, certificates);
	NSLog(@"SSLSetCertificate(): %d", result);
	CFRelease(certificates);
	
	// Perform SSL handshake.
	do {
		result = SSLHandshake(context);
		NSLog(@"SSLHandshake(): %d", result);
	} while(result == errSSLWouldBlock);
	
}

- (void)disconnect {
	
	if(self.certificate == nil) {
		return;
	}
	
	// Define result variable.
	OSStatus result;
	
	// Close SSL session.
	result = SSLClose(context);
	NSLog(@"SSLClose(): %d", result);
	
	// Release identity.
	CFRelease(identity);
	
	// Release certificate.
	CFRelease(certificate);
	
	// Release keychain.
	CFRelease(keychain);
	
	// Close connection to server.
	close((int)socket);
	
	// Delete SSL context.
	result = SSLDisposeContext(context);
	NSLog(@"SSLDisposeContext(): %d", result);
	
}

#pragma mark IBAction

- (void)internalNotify
{
    if(self.certificate == nil) {
		return;
	}
	
	// Validate input.
	if(self.deviceToken == nil || self.payload == nil) {
		return;
	}
	
	// Convert string into device token data.
	NSMutableData *deviceToken = [NSMutableData data];
	unsigned value;
	NSScanner *scanner = [NSScanner scannerWithString:self.deviceToken];
	while(![scanner isAtEnd]) {
		[scanner scanHexInt:&value];
		value = htonl(value);
		[deviceToken appendBytes:&value length:sizeof(value)];
	}
	
	// Create C input variables.
	char *deviceTokenBinary = (char *)[deviceToken bytes];
	char *payloadBinary = (char *)[self.payload UTF8String];
	size_t payloadLength = strlen(payloadBinary);
	
	// Define some variables.
	uint8_t command = 0;
	char message[293];
	char *pointer = message;
	uint16_t networkTokenLength = htons(32);
	uint16_t networkPayloadLength = htons(payloadLength);
	
	// Compose message.
	memcpy(pointer, &command, sizeof(uint8_t));
	pointer += sizeof(uint8_t);
	memcpy(pointer, &networkTokenLength, sizeof(uint16_t));
	pointer += sizeof(uint16_t);
	memcpy(pointer, deviceTokenBinary, 32);
	pointer += 32;
	memcpy(pointer, &networkPayloadLength, sizeof(uint16_t));
	pointer += sizeof(uint16_t);
	memcpy(pointer, payloadBinary, payloadLength);
	pointer += payloadLength;
	
	// Send message over SSL.
	size_t processed = 0;
	OSStatus result = SSLWrite(context, &message, (pointer - message), &processed); 
	NSLog(@"SSLWrite(): %d %ld", result, processed);
}

- (IBAction)doSelectSound:(id)sender
{
    NSMatrix *matrix = sender;
    NSArray *selects = [matrix selectedCells];
    
    if (selects.count > 0) {
        NSButtonCell *cell = [selects objectAtIndex:0];
        self.soundName = cell.title;
    }
}


- (IBAction)pushNotify:(id)sender 
{
    NSInteger badge = [_txtBadgeNumber.stringValue intValue];
    for (NSInteger i=0; i<_devices.count ; i++) {
         KSDeviceInfo *info = [_devices objectAtIndex:i];
        
        if (info.state==1) {
        
            self.deviceToken = info.token;
            self.payload = [NSString stringWithFormat:@"{\"aps\":{\"alert\":\"%@\",\"badge\":%d,\"sound\":\"%@\"}}",_txtAlertBody.stringValue, badge,soundName]; 
            
            [self internalNotify];
        }
    }
}

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSButtonCell *cellObj = cell;
    KSDeviceInfo *device = [_devices objectAtIndex:row];
    cellObj.title = device.name;
}

-(void)CellClick:(id)sender
{
    NSButtonCell* cell=(NSButtonCell *)[_tableView selectedCell];
    
    if([cell state]==1)
        [cell setState:0];
    else {
        [cell setState:1];
    }
}

-(id)tableView:(NSTableView *)tv objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSButtonCell *cellObj = [tableColumn dataCellForRow:row];
    
    KSDeviceInfo *device = [_devices objectAtIndex:row];

    [cellObj setTag:row];
    [cellObj setAction:@selector(CellClick:)];
    [cellObj setTarget:self];
    [cellObj setState:device.state];
    
    return cellObj;
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    KSDeviceInfo *dev=[_devices objectAtIndex:rowIndex];
    if (dev.state ==1) {
        dev.state =0;
    }
    else {
        dev.state =1;
    }
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return _devices.count;
}

@end
