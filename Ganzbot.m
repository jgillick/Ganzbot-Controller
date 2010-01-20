//
//  Ganzbot.m
//  Ganzbot Controller
//
//  Created by Jeremy Gillick on 1/15/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Ganzbot.h"
#import "GanzbotPrefs.h"
#import "AudioDevices.h"


@implementation Ganzbot

- (id)init {
	self = [super init];
	
	if(self){
		speechFile = @"/Users/jeremy/speech.aif";
		synth = [[NSSpeechSynthesizer alloc] init];
		[synth setDelegate:self];
	}
	
	return self;
}

- (void)say: (NSString *)message {
	
	if([synth isSpeaking]){
		NSLog(@"Currently speaking");
		return;
	}
	
	// Save to audio file
	NSURL *url = [NSURL fileURLWithPath:speechFile];
	[synth startSpeakingString:message toURL:url];
}

// Called when the speech synth has finished writing the speech file
- (void)speechSynthesizer:(NSSpeechSynthesizer *)sender didFinishSpeaking:(BOOL)success {
	NSSound *sound = [[NSSound alloc] initWithContentsOfFile:speechFile byReference:YES];
	
	NSDictionary *device = [GanzbotPrefs getAudioDevice];
	[sound setPlaybackDeviceIdentifier: [device valueForKey:@"uid"] ];
	[sound play];
	NSLog(@"Use device %@", [device valueForKey:@"name"]);
}


- (void) setVoice: (NSDictionary *)voiceAttr {
	[synth setVoice: [voiceAttr valueForKey: @"VoiceIdentifier"] ];
}

- (void) setRate: (float) speed {
	[synth setRate: speed];
}

@end
