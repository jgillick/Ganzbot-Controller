//
//  SerialDevice.m
//  Ganzbot
//
//  Created by Jeremy Gillick on 2/17/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//
#import "SerialDevice.h"


@implementation SerialDevice
@synthesize name;
@synthesize path;
@synthesize buffer;
@synthesize dataBufferSize;
@synthesize delegate;

/**
 * Get a list of all serial devices on this machine
 */
+ (NSArray *)allSerialDevices {
	NSMutableArray *devices = [[[NSMutableArray alloc] init] autorelease];
	
	// Ask for all the serial ports
	io_object_t serialPort;
	io_iterator_t serialPortIterator;
	IOServiceGetMatchingServices(kIOMasterPortDefault, IOServiceMatching(kIOSerialBSDServiceValue), &serialPortIterator);
	
	
	// Loop through the serial devices
	while (serialPort = IOIteratorNext(serialPortIterator)) {
		NSString *portPath = (NSString*)IORegistryEntryCreateCFProperty(serialPort, CFSTR(kIOCalloutDeviceKey),  kCFAllocatorDefault, 0);
		SerialDevice *device = [[[SerialDevice alloc] init: portPath] autorelease];
		[devices addObject:device];
		
		IOObjectRelease(serialPort);
	}
	IOObjectRelease(serialPortIterator);
	
	return devices;
}

/**
 * Create a new serial device
 */
- (id)init: (NSString *)usePath {	
	return [self init:usePath withDataBoundary:nil];
}

/**
 * Create a new serial device with a data boundary.
 * When a data boundary is present, the received data will not be sent to the delagate
 * until that character is sent or the dataBufferSize is reached.
 *
 * For example, if the data boundary is "\n", the following would send "hello" and "world" to the delegate
 * but not foo:
 *		hello\nworld\nfoo
 *
 */
- (id)init: (NSString *)usePath withDataBoundary:(char)useDataBoundary {
	path = usePath;
	name = [path lastPathComponent];
	dataBoundary = useDataBoundary;
	
	dataBufferSize = 200;
	buffer = [[[NSMutableData alloc] init] autorelease];
	
	// we don't have a serial port open yet
	serialFileDescriptor = -1;
	readThreadRunning = FALSE;
	
	return self;
}

/**
 * Open the serial port
 * nil on success
 * error on failure
 */
- (NSString *) open: (speed_t)baudRate {
	int success;
	[self flushBuffer];
	
	// close the port if it is already open
	if (serialFileDescriptor != -1) {
		close(serialFileDescriptor);
		serialFileDescriptor = -1;
		
		// wait for the reading thread to die
		while(readThreadRunning);
		
		// re-opening the same port REALLY fast will fail spectacularly... better to sleep a sec
		sleep(0.5);
	}
	
	// c-string path to serial-port file
	const char *bsdPath = [path cStringUsingEncoding:NSUTF8StringEncoding];
	
	// Hold the original termios attributes we are setting
	struct termios options;
	
	// receive latency ( in microseconds )
	unsigned long mics = 3;
	
	// error message string
	NSMutableString *errorMessage = nil;
	
	// open the port
	//     O_NONBLOCK causes the port to open without any delay (we'll block with another call)
	serialFileDescriptor = open(bsdPath, O_RDWR | O_NOCTTY | O_NONBLOCK );
	
	if (serialFileDescriptor == -1) { 
		// check if the port opened correctly
		errorMessage = @"Error: couldn't open serial port";
	} else {
		// TIOCEXCL causes blocking of non-root processes on this serial-port
		success = ioctl(serialFileDescriptor, TIOCEXCL);
		if ( success == -1) { 
			errorMessage = @"Error: couldn't obtain lock on serial port";
		} else {
			success = fcntl(serialFileDescriptor, F_SETFL, 0);
			if ( success == -1) { 
				// clear the O_NONBLOCK flag; all calls from here on out are blocking for non-root processes
				errorMessage = @"Error: couldn't obtain lock on serial port";
			} else {
				// Get the current options and save them so we can restore the default settings later.
				success = tcgetattr(serialFileDescriptor, &gOriginalTTYAttrs);
				if ( success == -1) { 
					errorMessage = @"Error: couldn't get serial attributes";
				} else {
					// copy the old termios settings into the current
					//   you want to do this so that you get all the control characters assigned
					options = gOriginalTTYAttrs;
					
					/*
					 cfmakeraw(&options) is equivilent to:
					 options->c_iflag &= ~(IGNBRK | BRKINT | PARMRK | ISTRIP | INLCR | IGNCR | ICRNL | IXON);
					 options->c_oflag &= ~OPOST;
					 options->c_lflag &= ~(ECHO | ECHONL | ICANON | ISIG | IEXTEN);
					 options->c_cflag &= ~(CSIZE | PARENB);
					 options->c_cflag |= CS8;
					 */
					cfmakeraw(&options);
					
					// set tty attributes (raw-mode in this case)
					success = tcsetattr(serialFileDescriptor, TCSANOW, &options);
					if ( success == -1) {
						errorMessage = @"Error: coudln't set serial attributes";
					} else {
						// Set baud rate (any arbitrary baud rate can be set this way)
						success = ioctl(serialFileDescriptor, IOSSIOSPEED, &baudRate);
						if ( success == -1) { 
							errorMessage = @"Error: Baud Rate out of bounds";
						} else {
							// Set the receive latency (a.k.a. don't wait to buffer data)
							success = ioctl(serialFileDescriptor, IOSSDATALAT, &mics);
							if ( success == -1) { 
								errorMessage = @"Error: coudln't set serial latency";
							}
						}
					}
				}
			}
		}
	}
	
	// make sure the port is closed if a problem happens
	if ((serialFileDescriptor != -1) && (errorMessage != nil)) {
		close(serialFileDescriptor);
		serialFileDescriptor = -1;
	}
	
	[self performSelectorInBackground:@selector(incomingSerialData:) withObject:[NSThread currentThread]];
	
	return errorMessage;
}

/**
 * Close the serial device
 */
- (void)close{
	close(serialFileDescriptor);
}

/**
 * send a string to the serial port
 */
- (void) writeString: (NSString *) str {
	if(serialFileDescriptor != -1) {
		write(serialFileDescriptor, [str cStringUsingEncoding:NSUTF8StringEncoding], [str length]);
	}
}

/** 
 * send a byte to the serial port
 */
- (void) writeByte: (uint8_t *) val {
	if(serialFileDescriptor!=-1) {
		write(serialFileDescriptor, val, 1);
	}
}

/**
 * Clear the data buffer
 */
- (void)flushBuffer {
	[buffer dealloc];
	buffer = [[[NSMutableData alloc] init] autorelease];
}

/**
 * Send part of the data buffer to the delegate
 */
- (void)sendDataToDelegate: (NSData *)data{
	if (self.delegate != NULL && [self.delegate respondsToSelector:@selector(serialPortReadData:)]) {
		[delegate serialPortReadData:data];	
	}
}

/**
 * This thread will read from the serial port and exits when the port is closed
 */
- (void)incomingSerialData: (NSThread *) parentThread {

	// create a pool so we can use regular Cocoa stuff
	//   child threads can't re-use the parent's autorelease pool
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	// mark that the thread is running
	readThreadRunning = TRUE;
	
	char byte_buffer[dataBufferSize]; // buffer for holding incoming data
	int numBytes=0; // number of bytes read during read
	
	// assign a high priority to this thread
	[NSThread setThreadPriority:1.0];
	
	// this will loop unitl the serial port closes
	while(TRUE) {
		// read() blocks until some data is available or the port is closed
		numBytes = read(serialFileDescriptor, byte_buffer, dataBufferSize); // read up to the size of the buffer
		if(numBytes > 0) {
			// Add bytes to buffer
			[buffer appendBytes:byte_buffer length:numBytes];
		}
		
		
		// Send data to delegate
		if(numBytes == 0 || &dataBoundary == nil || [buffer length] >= dataBufferSize){
			[self performSelectorOnMainThread:@selector(sendDataToDelegate:)
								   withObject:buffer
								waitUntilDone:YES];
			[self performSelectorOnMainThread:@selector(flushBuffer)
								   withObject:nil
								waitUntilDone:YES];
		}
		// Send data if a dataBoundary is found
		else if(&dataBoundary != nil){
			NSMutableData *send = [[[NSMutableData alloc] init] autorelease];
			char *all_bytes = [buffer mutableBytes];
			int lastFound = 0;
			int length = [buffer length];
			
			for(int i = 0; i < length; i++){
				[send appendBytes: &all_bytes[i] length:1];
				
				// Found boundary. Send!
				if(all_bytes[i] == dataBoundary){
					lastFound = i;
					[self performSelectorOnMainThread:@selector(sendDataToDelegate:)
										   withObject:send
										waitUntilDone:YES];
					
					// Start with fresh buffer
					send = [[[NSMutableData alloc] init] autorelease];
				}
			}
			
			// Remove sent data from the buffer
			if(lastFound > 0){
				lastFound++;
				NSRange range = {lastFound, length - lastFound};
				NSData *newBuffer = [buffer subdataWithRange:range];
				buffer = [buffer initWithData: newBuffer];
				[newBuffer dealloc];
			}
			
			[send dealloc];
			all_bytes = nil;
		}
		
		// No data == error
		if(numBytes == 0){
			break;
		}
	}
	
	// make sure the serial port is closed
	if (serialFileDescriptor != -1) {
		close(serialFileDescriptor);
		serialFileDescriptor = -1;
	}
	
	// mark that the thread has quit
	readThreadRunning = FALSE;
	
	// give back the pool
	[pool release];
}

@end
