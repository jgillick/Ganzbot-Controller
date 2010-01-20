//
//  GanzbotServer.m
//  Ganzbot Controller
//
//  Created by Jeremy Gillick on 1/19/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "GanzbotServer.h"


@implementation GanzbotServer
@synthesize httpServer;

- (id)init{
	if(self = [super init]){
		httpServer = [[HTTPServer alloc] init];
		
		// Doc root
		NSString *webPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Web"];
		[httpServer setDocumentRoot:[NSURL fileURLWithPath:webPath]];
		
		// Handle POST & GET actions
		[httpServer setConnectionClass:[self class]];
	}
	return self;
}



@end
