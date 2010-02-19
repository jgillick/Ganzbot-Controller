//
//  Ganzbot.h
//  Ganzbot Controller
//
//  Created by Jeremy Gillick on 1/15/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//
#import <Cocoa/Cocoa.h>
#import "GanzbotQueue.h"
#import "GanzbotPrefs.h"
#import "SerialDevice.h"

#define DEVICE_TYPE_NONE 0
#define DEVICE_TYPE_SERIAL 1
#define DEVICE_TYPE_REMOTE 2

@interface Ganzbot : NSObject {
	id delegate;
	
	NSString *speechFile;
	NSSpeechSynthesizer *synth;
	NSManagedObject *currentMessage;
	NSSound *sound;
	
	GanzbotQueue *queue;
	NSUserDefaults *prefs;
	
	NSString *ganzbotDevice;
	UInt32 ganbotDeviceType;
	SerialDevice *serialPort;
	BOOL ganzbotOn; // is the ganzbot device on?
}

@property (assign) id delegate;
@property (readonly) BOOL ganzbotOn;
@property (readonly) GanzbotQueue *queue;

- (id) initWithQueue: (GanzbotQueue *)useQueue;
- (void) say: (NSString *)message;
- (void) say: (NSString *)message withVoice:(NSString *)voiceName withRate:(NSNumber *)rate;
- (NSDictionary *)getVoiceForName: (NSString *)name;
- (NSDictionary *) decodeMessage: (NSString *)encoded;
- (void)speakNextInQueue;
- (NSString *)setGanzbotDevice: (NSString *)device forType:(UInt32)type;
- (void)serialPortReadData:(NSData *)data;

@end
