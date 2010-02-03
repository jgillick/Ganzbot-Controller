//
//  GanzbotPrefs.m
//  Ganzbot Controller
//
//  Created by Jeremy Gillick on 1/18/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "GanzbotPrefs.h"
#import "AudioDevices.h"

@implementation GanzbotPrefs

+ (NSUserDefaults *) loadPrefs{
		
	// Set default prefs
	NSUserDefaults *preferences = [[NSUserDefaults standardUserDefaults] retain];
	NSString *file = [[NSBundle mainBundle]
					  pathForResource:@"Defaults" ofType:@"plist"];
	NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:file];
	[preferences registerDefaults:dict];		
	
	return preferences;	
}

+ (NSDictionary *) getAudioDevice{

	NSUserDefaults *prefs = [GanzbotPrefs loadPrefs];
	NSString *uid = [prefs objectForKey:@"outputDevice"];
	NSDictionary *device = NULL;
	
	if (uid) {
		device = [AudioDevices getDeviceByUID:uid];
	}
	
	// Device doesn't exist (unplugged?)
	if(device == NULL){
		NSLog(@"Saved device UID does not exist. Has it been disconnected? (using default output device)");
		device = [AudioDevices getDefaultOutputDevice];
	}
	
	return device;
}

@end
