//
//  SerialDevice.h
//  Ganzbot
//
//  Created by Jeremy Gillick on 2/17/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

// import IOKit headers
#include <IOKit/IOKitLib.h>
#include <IOKit/serial/IOSerialKeys.h>
#include <IOKit/IOBSD.h>
#include <IOKit/serial/ioss.h>
#include <sys/ioctl.h>


@interface SerialDevice : NSObject {
	NSString *name;
	NSString *path;
	
	NSMutableData *buffer;
	char dataBoundary;
	int dataBufferSize;
	
	id delegate;
	
	int serialFileDescriptor; // file handle to the serial port
	struct termios gOriginalTTYAttrs; // Hold the original termios attributes so we can reset them on quit ( best practice )
	bool readThreadRunning;
}

@property (assign) id delegate;
@property (readonly) NSString *name;
@property (readonly) NSString *path;
@property (readonly) NSData *buffer;
@property (assign) int dataBufferSize;

+ (NSArray *)allSerialDevices;
- (id)init: (NSString *)usePath;
- (id)init: (NSString *)usePath withDataBoundary:(char)useDataBoundary;

- (NSString *) open: (speed_t)baudRate;
- (void)close;

- (void) writeString: (NSString *) str;
- (void) writeByte: (uint8_t *) val;

- (NSData *) getBuffer;
- (void) flushBuffer;
- (void)sendDataToDelegate: (NSData *)data;

@end
