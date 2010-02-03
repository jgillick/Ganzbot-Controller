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
#import "AMSerialPortList.h"
#import "AMSerialPortAdditions.h"

#define DEVICE_TYPE_NONE 0
#define DEVICE_TYPE_SERIAL 1
#define DEVICE_TYPE_REMOTE 2

@interface Ganzbot : NSObject {
	NSString *speechFile;
	NSSpeechSynthesizer *synth;
	NSManagedObject *currentMessage;
	NSSound *sound;
	
	GanzbotQueue *queue;
	NSUserDefaults *prefs;
	
	NSString *ganzbotDevice;
	UInt32 ganbotDeviceType;
	AMSerialPort *serialPort;
}

@property (readonly) GanzbotQueue *queue;

- (id) initWithQueue: (GanzbotQueue *)useQueue;
- (void) say: (NSString *)message;
- (void) say: (NSString *)message withVoice:(NSString *)voiceName withRate:(NSNumber *)rate;
- (NSDictionary *)getVoiceForName: (NSString *)name;
- (NSDictionary *) decodeMessage: (NSString *)encoded;
- (void)speakNextInQueue;
- (BOOL)setGanzbotDevice: (NSString *)device forType:(UInt32)type;

@end
