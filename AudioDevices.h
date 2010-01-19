//
//  AudioDevices.h
//  Ganzbot Controller
//
//  Created by Jeremy Gillick on 1/18/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CoreAudio/CoreAudio.h>

@interface AudioDevices : NSObject {

}

+ (NSArray *) getDeviceList;
+ (NSDictionary *) getDefaultOutputDevice;
+ (NSDictionary *) getDeviceByID: (AudioDeviceID)deviceID;

@end
