//
//  Ganzbot.h
//  Ganzbot Controller
//
//  Created by Jeremy Gillick on 1/15/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//
#import <Cocoa/Cocoa.h>


@interface Ganzbot : NSObject {
	bool isTalking, isRobotReady;
	
	NSString *speechFile;
	NSSpeechSynthesizer *synth;
}

- (void) setRate: (float) speed;
- (void) setVoice: (NSDictionary*) voiceAttr;
- (void) say: (NSString*)message;

@end
