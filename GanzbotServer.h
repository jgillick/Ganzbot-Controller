//
//  GanzbotServer.h
//  Ganzbot Controller
//
//  Created by Jeremy Gillick on 1/19/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HTTPServer.h"
#import "HTTPConnection.h"

@interface GanzbotServer : HTTPConnection {
	HTTPServer *httpServer;
	NSInteger status;
}

@property (readonly) NSInteger status;
@property (readonly) HTTPServer *httpServer;

- (BOOL)start:(NSInteger)port error:(NSError **)useError;
- (BOOL)stop;

@end
