//
//  AudioDevices.m
//  Ganzbot Controller
//	Code copied from OSX references (http://developer.apple.com/mac/library/samplecode/AudioDeviceNotify/listing2.html)
//
//  Created by Jeremy Gillick on 1/18/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "AudioDevices.h"

@implementation AudioDevices

static OSStatus GetAudioDevices( Ptr * devices, UInt16 * devicesAvailable )
{
	
	OSStatus	err = noErr;
    UInt32 		outSize;
    Boolean		outWritable;
    
    // find out how many audio devices there are, if any
    err = AudioHardwareGetPropertyInfo(kAudioHardwarePropertyDevices, &outSize, &outWritable);	
    if ( err != noErr ) 
		return err;
	
    // calculate the number of device available
	*devicesAvailable = outSize / sizeof(AudioDeviceID);						
    if ( *devicesAvailable < 1 )
	{
		fprintf( stderr, "No devices\n" );
		return err;
	}
    
    // make space for the devices we are about to get
    *devices = (Ptr) malloc(outSize);		
	
    memset( *devices, 0, outSize );			
    err = AudioHardwareGetProperty(kAudioHardwarePropertyDevices, &outSize, (void *) *devices);	
    if (err != noErr )
		return err;
	
    return err;
}

+ (NSDictionary *) getDefaultOutputDevice
{
	UInt32				outSize;
	AudioDeviceID		deviceID;
	NSDictionary		*device;
	
	outSize = sizeof deviceID;
	AudioHardwareGetProperty(kAudioHardwarePropertyDefaultOutputDevice, &outSize, &deviceID);
	device = [AudioDevices getDeviceByID:(UInt32)deviceID];
	
    return device;	
}

+ (NSDictionary *) getDeviceByID: (AudioDeviceID)deviceID
{
	OSStatus	err = noErr;
    UInt32 		outSize = 0;
	UInt32      theNumberInputChannels  = 0;
	UInt32      theNumberOutputChannels = 0;
	UInt32      theIndex = 0;
	AudioBufferList		*theBufferList = NULL;
	CFStringRef			tempStringRef = NULL;
	NSMutableDictionary *details = [[NSMutableDictionary alloc] init];
	
	// save device id
	[details setObject:[NSNumber numberWithInt: deviceID] forKey:@"id"];
	
	// get device name
	outSize = sizeof(CFStringRef);
	err = AudioDeviceGetProperty( deviceID, 0, 0, kAudioDevicePropertyDeviceNameCFString, &outSize, &tempStringRef);
	if(tempStringRef)
	{
		[details setObject:(NSString *)tempStringRef forKey:@"name"];
		CFRelease(tempStringRef);
	}
	
	// Device UID
	outSize = sizeof(CFStringRef);
	err = AudioDeviceGetProperty( deviceID, 0, 0, kAudioDevicePropertyDeviceUID, &outSize, &tempStringRef);
	if(tempStringRef)
	{
		[details setObject:(NSString *)tempStringRef forKey:@"uid"];
		CFRelease(tempStringRef);
	}
	
	// get number of input channels
	outSize = 0;
	theNumberInputChannels = 0;
	err = AudioDeviceGetPropertyInfo( deviceID, 0, 1, kAudioDevicePropertyStreamConfiguration, &outSize, NULL);
	if((err == noErr) && (outSize != 0))
	{
		theBufferList = (AudioBufferList*)malloc(outSize);
		if(theBufferList != NULL)
		{
			// get the input stream configuration
			err = AudioDeviceGetProperty( deviceID, 0, 1, kAudioDevicePropertyStreamConfiguration, &outSize, 
										 theBufferList);
			if(err == noErr)
			{
				// count the total number of input channels in the stream
				for(theIndex = 0; theIndex < theBufferList->mNumberBuffers; ++theIndex)
					theNumberInputChannels += theBufferList->mBuffers[theIndex].mNumberChannels;
			}
			free(theBufferList);
			
			[details setObject: [NSNumber numberWithInt:theNumberInputChannels] forKey:@"ich"];
		}
	}
	
	// get number of output channels
	outSize = 0;
	theNumberOutputChannels = 0;
	err = AudioDeviceGetPropertyInfo( deviceID, 0, 0, kAudioDevicePropertyStreamConfiguration, &outSize, NULL);
	if((err == noErr) && (outSize != 0))
	{
		theBufferList = (AudioBufferList*)malloc(outSize);
		if(theBufferList != NULL)
		{
			// get the input stream configuration
			err = AudioDeviceGetProperty( deviceID, 0, 0, kAudioDevicePropertyStreamConfiguration, &outSize, 
										 theBufferList);
			if(err == noErr)
			{
				// count the total number of output channels in the stream
				for(theIndex = 0; theIndex < theBufferList->mNumberBuffers; ++theIndex)
					theNumberOutputChannels += theBufferList->mBuffers[theIndex].mNumberChannels;
			}
			free(theBufferList);
			[details setObject:[NSNumber numberWithInt:theNumberOutputChannels] forKey:@"och"];
		}
	}
	
	return details;
}

+ (NSArray *) getDeviceList
{
	
    UInt16		devicesAvailable = 0;
	UInt16		loopCount = 0;
    AudioDeviceID	*devices = NULL;
	NSMutableArray	*deviceArray = [[NSMutableArray alloc] init];

	// fetch a pointer to the list of available devices
	if(GetAudioDevices((Ptr*)&devices, &devicesAvailable) != noErr)
		return deviceArray;
	
	// iterate over each device gathering information
	for(loopCount = 0; loopCount < devicesAvailable; loopCount++)
	{
		NSDictionary *device = [AudioDevices getDeviceByID: devices[loopCount]];
		[deviceArray addObject:(NSDictionary*)device];
		[device release];
	}
	
	return deviceArray;
	
}

@end
