//
//  GanzbotController.m
//  Ganzbot Controller
//
//  Created by Jeremy Gillick on 1/15/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "GanzbotController.h"
#import "AudioDevices.h"
#import "GanzbotServer.h"
#import "HTTPServer.h"
#import "SerialDevice.h"

@implementation GanzbotController

- (id)init{
	if(self = [super init]){
		prefs = [GanzbotPrefs loadPrefs];
		queue = [[GanzbotQueue alloc] init];
		[self managedObjectContext];
	}
	return self;
}

- (void)awakeFromNib {
	int i, count;
	
	ganzbot = [[Ganzbot alloc] initWithQueue: queue];
	gserver = [[GanzbotServer alloc] initWithGanzbot:ganzbot];
	
	// Set table data sorting
	NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"created_on" ascending:NO];
	NSArray *sorts = [NSArray arrayWithObject:sort];
	[historyArray setSortDescriptors: sorts];
	
	sort = [[NSSortDescriptor alloc] initWithKey:@"created_on" ascending:YES];
	sorts = [NSArray arrayWithObject:sort];
	[queueArray setSortDescriptors:sorts];
	
	[sort release];	
	
	// Get selected voice
	NSString *selectedVoice = [prefs stringForKey: @"voice"];
	
	// List the available voices
	NSArray *voices = [NSSpeechSynthesizer availableVoices];
	count = [voices count];
	for (i = 0; i < count; i++) {
		NSString *voiceId = [voices objectAtIndex:i];
		NSDictionary *voice = [NSSpeechSynthesizer attributesForVoice: voiceId];
		NSString *name = (NSString *)[voice valueForKey: @"VoiceName"];
		
		// Add item to list
		[voicesList addItemWithTitle: name];
		NSMenuItem *item = [voicesList lastItem];
		[item setRepresentedObject: voice];
		
		// Selected
		if([voiceId isEqualToString: selectedVoice]){
			[voicesList selectItem: item];
		}
	}
	
	// List available output devices
	NSArray *outputs = [AudioDevices getDeviceList];
	NSDictionary *selectedAudioDevice = [GanzbotPrefs getAudioDevice];
	NSString *selectedUID = [selectedAudioDevice objectForKey:@"uid"];
	count = [outputs count];
	for( i = 0; i < count; i++ ){
		NSDictionary *output = (NSDictionary *)[outputs objectAtIndex:i];
		NSNumber *outChannels = (NSNumber *)[output valueForKey:@"och"];
		NSString *deviceUID = [output valueForKey:@"uid"];
		
		// Only list devices with output channels
		if([outChannels intValue] > 0){
			[outputDeviceList addItemWithTitle: [output valueForKey:@"name"] ];
			NSMenuItem *item = [outputDeviceList lastItem];
			[item setRepresentedObject: output];
			
			// Selected
			if([deviceUID isEqualToString:selectedUID] ){
				[outputDeviceList selectItem: item];
			}
		}
	}
	
	// Open drawer
	if( [prefs boolForKey:@"isDrawerOpen"] ){
		[drawerPanel open];
	}
	else{
		[drawerPanel close];
	}
}

/**
 * After the app has launched
 */
-(void)applicationDidFinishLaunching:(NSNotification*)aNotification {
		
	// Start server
	if( [prefs boolForKey:@"serverStartAtLaunch"] ){
		[self toggleServer:nil];
	}
	
	// Serial devices
	[self updateSerialList];
}

/**
 * Updates the serial port list
 */
- (void)updateSerialList{
	
	// Remove all items
	[serialDeviceList removeAllItems];
	[serialDeviceList addItemWithTitle:@"None"];
	[[serialDeviceList lastItem] setTag:DEVICE_TYPE_NONE];
	
	[ganzbot setGanzbotDevice:nil forType:DEVICE_TYPE_NONE];
	
	
	// Add serial devices
	NSArray *devices = [SerialDevice allSerialDevices];
	NSString *selectedSerialDevice = [prefs stringForKey: @"serialDevice"];
	for(int i = 0; i < [devices count]; i++){
		SerialDevice *device = [devices objectAtIndex:i];
		
		[serialDeviceList addItemWithTitle:[device name]];	
		NSMenuItem *item = [serialDeviceList lastItem];
		[item setRepresentedObject: device];
		
		// This is the selected device, connect to it
		if( [selectedSerialDevice isEqualToString:[device name]] ){
			[serialDeviceList selectItem:[serialDeviceList lastItem]];

			// Connect
			NSString *error = [ganzbot setGanzbotDevice:[device path] forType:DEVICE_TYPE_SERIAL];
			if(error == nil){
				[serialDeviceList selectItem:item];
				//[ganzbot speakNextInQueue];
			}
			// Error
			else{
				NSString *errMsg = [[NSString alloc] initWithFormat:@"Could not connect to Ganzbot device:\n%@\n\n%@", [device name], error];
				NSAlert *alert = [NSAlert alertWithMessageText:@"An error ocurred"
												 defaultButton:@"OK" alternateButton:nil otherButton:nil
									 informativeTextWithFormat:errMsg];	
				[alert beginSheetModalForWindow:window modalDelegate:self didEndSelector:nil contextInfo:nil];
				
				[prefs setObject:@"None" forKey:@"serialDevice"];
			}
		}
	}
}

/**
 * When a serial port is connected or disconnected
 */
- (void)didUpdatePorts:(NSNotification *)theNotification {
	[self updateSerialList];
}


/**
 * Tell ganzbot to speak a message
 */
- (IBAction)sayMessage:(id)sender{

	NSString *message = [messageField stringValue];
		
	// Get voice prefs
	NSNumber *rate = [NSNumber numberWithInt: [[speechRate selectedItem] tag] ];
	NSMenuItem *voiceItem = [voicesList selectedItem];
	NSDictionary *voiceAttr = [voiceItem representedObject];
	
	// Add to queue
	[ganzbot say:message withVoice:[voiceAttr objectForKey:@"VoiceIdentifier"] withRate:rate];
	
	// Empty field
	[messageField setStringValue:@""];
}

/*
 * Start/Stop the Ganzbot webserver
 */
- (IBAction)toggleServer: (id)sender {
	
	// Stop
	if( [gserver status] == 1 ){
		if([gserver stop]){
			[serverButton setTitle:@"Start"];
		}
		else{
			NSLog(@"Could not stop server. Hmmm. Weird");
		}
	}
	
	// Start
	else{
		NSError *error = nil;
		NSInteger port = [prefs integerForKey:@"serverPortNumber"];
		if( [gserver start:port	 error:&error] ){
			[serverButton setTitle:@"Stop"];
		}
		else{
			NSLog(@"Could not start server. %@", error);
		}
	}
}

/*
 * Save dropdown prefs
 */
- (IBAction)savePrefs: (id)sender {
	
	// Voice
	NSMenuItem *voiceItem = [voicesList selectedItem];
	NSDictionary *voiceAttr = [voiceItem representedObject];
	[prefs setObject: [voiceAttr valueForKey: @"VoiceIdentifier"] forKey: @"voice"];
	
	// Output device
	NSMenuItem *outputItem = [outputDeviceList selectedItem];
	NSDictionary *outputAttr = [outputItem representedObject];
	[prefs setObject: [outputAttr valueForKey: @"uid"] forKey: @"outputDevice"];
	
	// Update serial device list
	if(sender == serialDeviceList){
		[self updateSerialList];
	}
}

/* 
 * Save the drawer state
 */
- (void)drawerDidClose: (NSNotification *)notification {
	[prefs setBool:FALSE forKey: @"isDrawerOpen"];
}
- (void)drawerDidOpen: (NSNotification *)notification {
	[prefs setBool:TRUE forKey: @"isDrawerOpen"];	
}

/*
 * Core data context to update the UI
 */
- (NSManagedObjectContext *) managedObjectContext {
	managedObjectContext = [queue managedObjectContext];
	return managedObjectContext;
}

@end
