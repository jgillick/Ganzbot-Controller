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
#import "RegexKitLite.h"

#define DEFAULT_RATE 130.0

@implementation Ganzbot

@synthesize queue;
@synthesize ganzbotOn;
@synthesize delegate;

- (id)init {
	self = [super init];
	
	if(self){
		prefs = [GanzbotPrefs loadPrefs];
		
		// Synth and speech file
		speechFile = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"speech.aif"];
		synth = [[NSSpeechSynthesizer alloc] init];
		[synth setDelegate:self];
		
		ganzbotOn = NO;
	}
	
	return self;
}

- (id) initWithQueue: (GanzbotQueue *)useQueue {
	queue = useQueue;
	return [self init];
}


/**
 * Queue up a message to be spoken
 */
- (void)say: (NSString *)message {	
	NSDictionary *msg = [self decodeMessage:message];
	NSString *text = [msg objectForKey:@"text"];
	text = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	
	if([text isEqualTo:@""]){
		return;
	}
	
	NSLog(@"Queue message: '%@'", message);
	
	[self say:[msg objectForKey:@"text"]
	withVoice:[msg objectForKey:@"voice"] 
	 withRate:[msg objectForKey:@"rate"] ];
}

/**
 * Add a message with rate and voice values
 */
- (void) say: (NSString *)message withVoice:(NSString *)voiceName withRate:(NSNumber *)rate{
	[queue add:message voice:voiceName rate:rate];
	[self speakNextInQueue];
}

/**
 * Extract and set the voice and rate markers from the message
 */
- (NSDictionary *) decodeMessage: (NSString *)encoded{
	NSMutableDictionary *details = [[NSMutableDictionary alloc] init];
	
	// Separate message from synth options
	NSString *regexString = @"^\\s*(\\[(r|v)[^\\]]*\\])?(.*)$";
	NSString *synthValues = [encoded stringByMatching:regexString capture:1L];
	NSString *message = [encoded stringByMatching:regexString capture:3L];
	
	// Extract rate and voice
	float useRate;
	NSString *useVoice = nil;
	NSString *voice = [synthValues stringByMatching:@"v('|\")([a-zA-Z ]*)('|\")" capture:2L];
	NSString *rate = [synthValues stringByMatching:@"r([0-9]*)" capture:1L];
	
	// Set values we can use
	if(!rate || rate == 0){
		useRate = DEFAULT_RATE;
	}
	else{
		useRate = [rate floatValue];
	}
	
	NSDictionary *voiceAttr = [self getVoiceForName:voice];
	if(voiceAttr){
		useVoice = [voiceAttr objectForKey:@"VoiceIdentifier"];
	}
	else{
		useVoice = [prefs stringForKey: @"voice"];	
	}
	
	// Put it all together
	[details setObject:message forKey:@"text"];
	[details setObject:useVoice forKey:@"voice"];
	[details setObject:[NSNumber numberWithFloat: useRate] forKey:@"rate"];
	
	return details;
}

/**
 * Return the voice ID for the short name
 */
- (NSDictionary *)getVoiceForName: (NSString *)name {
	NSDictionary *voiceAttr = nil;
	
	// Empty name
	if([name isEqualToString:@""]){
		return nil;
	}
	
	// Is the name actually the ID
	voiceAttr = [NSSpeechSynthesizer attributesForVoice: name];
	if(voiceAttr){
		return voiceAttr;
	}
	
	// Loop through the voices
	name = [name lowercaseString];
	NSArray *voices = [NSSpeechSynthesizer availableVoices];
	for (NSInteger i = 0; i < [voices count]; i++) {
		NSString *voiceId = [voices objectAtIndex:i];
		voiceAttr = [NSSpeechSynthesizer attributesForVoice: voiceId];
		NSString *voiceName = (NSString *)[voiceAttr valueForKey: @"VoiceName"];
		voiceName = [voiceName lowercaseString];
		
		if([name isEqualTo:voiceName]){
			return voiceAttr;
		}
	}
	
	return nil;
}

/**
 * Read the next item in the queue
 */
- (void)speakNextInQueue {
	if( [synth isSpeaking] || (sound && [sound isPlaying]) ){
		NSLog(@"Currently speaking");
		return;
	}
	
	// Create audio file
	currentMessage = [queue getNextInQueue];
	if (currentMessage) {
		NSURL *url = [NSURL fileURLWithPath:speechFile];
		NSNumber *rate = [currentMessage valueForKey:@"rate"];
		NSString *message = [currentMessage valueForKey:@"text"];
		NSString *voice = [currentMessage valueForKey:@"voice"];
		NSDictionary *voiceAttr = [self getVoiceForName:voice];
		
		NSLog(@"Next in queue: '%@'", message);
		
		// Voice ID
		if(voiceAttr){
			voice = [voiceAttr objectForKey:@"VoiceIdentifier"];
		}
		else{
			voice = [prefs stringForKey: @"voice"];
		}
		
		// Empty message?
		message = [message stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		if([message isEqualTo:@""]){
			[queue markAsSpoken:currentMessage];
			[self speakNextInQueue];
			return;
		}
		
		// Zero rate
		if([rate floatValue] == 0.0){
			rate = [NSNumber numberWithFloat:DEFAULT_RATE];
		}
		
		// Synth speech properties
		[synth setVoice: voice];
		[synth setRate: [rate floatValue]];
		
		// Save synth to audio file
		[synth startSpeakingString:message toURL:url];
	}
	else{
		NSLog(@"Empty queue");
	}
}

/**
 * Play the message audio file
 */
- (void)playMessage{
	
	// Tell Ganzbot we're starting to speak
	if(ganbotDeviceType == DEVICE_TYPE_SERIAL && serialPort){
		[serialPort writeString:@"S\n"];
	}
	
	// Play
	NSDictionary *device = [GanzbotPrefs getAudioDevice];
	[sound setPlaybackDeviceIdentifier: [device valueForKey:@"uid"] ];
	[sound setDelegate:self];
	[sound play];
}

/**
 * Played the saved speech synthesised message
 */
- (void)speechSynthesizer:(NSSpeechSynthesizer *)sender didFinishSpeaking:(BOOL)success {
	sound = [[NSSound alloc] initWithContentsOfFile:speechFile byReference:YES];
	
	// Wait until the robot is ready to speak
	if(ganbotDeviceType == DEVICE_TYPE_SERIAL && serialPort){
		[serialPort writeString:@"\nR\n"];
	}
	else{
		[self playMessage];
	}
}

/**
 * Message done, play the next in queue
 */
- (void)sound:(NSSound *)sound didFinishPlaying:(BOOL)finishedPlaying {
	
	// Tell Ganzbot we're done
	if(ganbotDeviceType == DEVICE_TYPE_SERIAL && serialPort){
		[serialPort writeString:@"E\n"];
	}
	
	if (currentMessage) {
		[queue markAsSpoken:currentMessage];
	}
	[self speakNextInQueue];
}

/**
 * Set the ganzbot device
 */
- (NSString *)setGanzbotDevice: (NSString *)device forType:(UInt32)type{
	NSString *error = nil;
	ganzbotDevice = device;
	ganbotDeviceType = type;
	
	// Stop speaking
	[synth stopSpeaking];
	if(sound){
		[sound stop];
	}
	
	// Open serial port
	if(type == DEVICE_TYPE_SERIAL){
		if (![device isEqualToString:[serialPort path]]) {
			if(serialPort){
				[serialPort close];
				[serialPort release];
			}
			
			// Create new port
			serialPort = [[[SerialDevice alloc] init:device withDataBoundary:'\n'] autorelease];
			[serialPort setDelegate:self];
			error = [serialPort open: 9600];
		}
	}
	// Close any open serial ports
	else if(serialPort){
		[serialPort close];
		[serialPort release];
		serialPort = nil;
	}
	
	// Restart speaking
	[self speakNextInQueue];
	
	return error;
}

/**
 * When data is received from the serial port
 */
- (void)serialPortReadData:(NSData *)data {
	
	// Process returned cmd
	if ([data length] > 0) {
		NSString *cmd = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
		
		// Robot ready, play message
		if( [cmd isEqualToString:@"R\n"] ){
			[self playMessage];
		}
		else if( [cmd isEqualToString:@"B\n"] ){
			ganzbotOn = YES;
		}
		else{
			NSLog(@">> %@", cmd);
		}
			
		[cmd release];
	}
	
}
	   
- (void)dealloc {
	[synth release];
	
	if(sound){
		[sound release];
	}
	
	[super dealloc];
}

@end
