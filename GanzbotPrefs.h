//
//  GanzbotPrefs.h
//  Ganzbot Controller
//
//  Created by Jeremy Gillick on 1/18/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface GanzbotPrefs : NSObject {
	
}

+ (NSUserDefaults *)loadPrefs;
+ (NSDictionary *)getAudioDevice;

@end
