//
//  Ganzbot.h
//  Ganzbot Controller
//
//  Created by Jeremy Gillick on 1/15/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//
#import <Cocoa/Cocoa.h>
#import	"GanzbotQueue.h"


@interface Ganzbot : NSObject {
	NSString *speechFile;
	NSSpeechSynthesizer *synth;
	GanzbotQueue *queue;
}

- (void) setRate: (float) speed;
- (void) setVoice: (NSDictionary*) voiceAttr;
- (void) say: (NSString*)message;

@end
