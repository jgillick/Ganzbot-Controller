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

@interface Ganzbot : NSObject {
	NSString *speechFile;
	NSSpeechSynthesizer *synth;
	NSManagedObject *currentMessage;
	NSSound *sound;
	
	GanzbotQueue *queue;
	NSUserDefaults *prefs;
}

@property (readonly) GanzbotQueue *queue;

- (id) initWithQueue: (GanzbotQueue *)useQueue;
- (void) say: (NSString *)message;
- (void) say: (NSString *)message withVoice:(NSString *)voiceName withRate:(NSNumber *)rate;
- (NSDictionary *)getVoiceForName: (NSString *)name;
- (NSDictionary *) decodeMessage: (NSString *)encoded;
- (void)speakNextInQueue;

@end
