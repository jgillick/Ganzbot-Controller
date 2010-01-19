//
//  GanzbotController.m
//  Ganzbot Controller
//
//  Created by Jeremy Gillick on 1/15/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "GanzbotController.h"
#import "AudioDevices.h"

@implementation GanzbotController

- (id)init{
	if(self = [super init]){
		prefs = [GanzbotPrefs loadPrefs];
	}
	return self;
}

- (void)awakeFromNib {
	int i, count;
	
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
	NSDictionary *selectedDevice = [GanzbotPrefs getAudioDevice];
	NSString *selectedUID = [selectedDevice objectForKey:@"uid"];
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
	

- (IBAction)sayMessage:(id)sender{

	NSString *message = [messageField stringValue];
	ganzbot = [[Ganzbot alloc]init];
		
	// Get voice prefs
	float rate = [[speechRate selectedItem] tag];
	NSMenuItem *voiceItem = [voicesList selectedItem];
	NSDictionary *voiceAttr = [voiceItem representedObject];
	
	
	[ganzbot setVoice: voiceAttr];
	[ganzbot setRate: rate];
	[ganzbot say: message];
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
	NSLog(@"save: %@", [outputAttr valueForKey: @"name"]);
	[prefs setObject: [outputAttr valueForKey: @"uid"] forKey: @"outputDevice"];
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

@end
