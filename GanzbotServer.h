//
//  GanzbotServer.h
//  Ganzbot Controller
//
//  Created by Jeremy Gillick on 1/19/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Ganzbot.h"
#import "GanzbotQueue.h"
#import "HTTPServer.h"
#import "HTTPConnection.h"
#import "MGTemplateEngine.h"

@interface GanzbotServer : HTTPConnection <MGTemplateEngineDelegate> {
	HTTPServer *httpServer;
	NSInteger status;
	MGTemplateEngine *tmplEngine;
}

@property (readonly) NSInteger status;
@property (readonly) HTTPServer *httpServer;
@property (readonly) MGTemplateEngine *tmplEngine;

+ (Ganzbot *)ganzbot;

- (id)initWithGanzbot: (Ganzbot *)useGanzbot;
- (BOOL)start:(NSInteger)port error:(NSError **)useError;
- (BOOL)stop;
- (NSDictionary *)readPostData;
- (void)redirect: (NSString *)url;
- (NSDictionary *)parseQuery:(NSString *)queryString;
- (NSString *)urlDecode:(NSString *)value;
- (NSString *)processTemplate: (NSString *)filePath;

@end
