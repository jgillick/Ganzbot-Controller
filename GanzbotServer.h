//
//  GanzbotServer.h
//  Ganzbot Controller
//
//  Created by Jeremy Gillick on 1/19/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HTTPServer.h"


@interface GanzbotServer : NSObject {
	HTTPServer *httpServer;
}

@property (readonly) HTTPServer *httpServer;

@end
