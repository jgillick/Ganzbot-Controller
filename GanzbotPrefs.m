//
//  GanzbotPrefs.m
//  Ganzbot Controller
//
//  Created by Jeremy Gillick on 1/18/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "GanzbotPrefs.h"


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

@end
