//
//  GanzbotServer.m
//  Ganzbot Controller
//
//  Created by Jeremy Gillick on 1/19/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "GanzbotServer.h"
#import "HTTPResponse.h"
#import "ICUTemplateMatcher.h"

static Ganzbot *ganzbot;

@implementation GanzbotServer
@synthesize status;
@synthesize httpServer;
@synthesize tmplEngine;

- (id)initWithGanzbot: (Ganzbot *)useGanzbot{
	ganzbot = useGanzbot;
	status = 0;
	httpServer = [[HTTPServer alloc] init];
							 
	// Handle POST & GET actions
	[httpServer setConnectionClass:[self class]];
	
	// Doc root
	NSString *webPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Web"];
	[httpServer setDocumentRoot:[NSURL fileURLWithPath:webPath]];
	
	return self;
}

// When HTTPConnection inits
- (id)initWithAsyncSocket:(AsyncSocket *)newSocket forServer:(HTTPServer *)myServer {
	
	// Template engine
	tmplEngine = [MGTemplateEngine templateEngine];
	[tmplEngine setDelegate:self];
	[tmplEngine loadFilter:self];
	[tmplEngine setMatcher:[ICUTemplateMatcher matcherWithTemplateEngine:tmplEngine]];
	
	return [super initWithAsyncSocket:newSocket forServer:myServer];
}

/**
 * Start the http server
 */
- (BOOL)start:(NSInteger)port error:(NSError **)useError {

	// Stop
	if(status == 1){
		[httpServer stop];
	}
	
	// Start
	[httpServer setPort:port];
	if( [httpServer start:useError] ) {
		status = 1;
		return YES;
	}
	return NO;
}

/**
 * Stop the http server
 */
- (BOOL)stop{
	if( [httpServer stop] ) {
		status = 0;
		return YES;
	}
	return NO;
}

/**
 * Handle requests to the server
 */
- (NSObject<HTTPResponse> *)httpResponseForMethod:(NSString *)method URI:(NSString *)path {
	
	BOOL isDirectory;
	NSString *tmplPath = [super filePathForURI: [@"/templates/" stringByAppendingPathComponent: path]];
	NSString *staticPath = [@"/static/" stringByAppendingPathComponent: path];
	NSString *fileName = [tmplPath lastPathComponent];
	NSString *ext = [tmplPath pathExtension];
	
	
	// Form processing for '.awesome' paths and POST method
	if([method isEqualToString:@"POST"] && [ext isEqualToString:@"awesome"]) {
		NSDictionary *data = [self readPostData];
		
		// Add the message to the queue
		if([fileName isEqualToString:@"add.awesome"] && [data objectForKey:@"text"] != nil){
			float rate = [[data objectForKey:@"rate"] floatValue];

			[ganzbot say:[data objectForKey:@"text"] 
			   withVoice:[data objectForKey:@"voice"]
				withRate:[NSNumber numberWithFloat: rate] 
			 ];
		}
		
		// Redirect to '/'
		if([[data objectForKey:@"responseType"] isEqualToString:@"json"]){
			[self redirect:@"/api.json"];
		}
		else{
			[self redirect:@"/"];
		}
		return NO;
	}
	// Templates
	else if([[NSFileManager defaultManager] fileExistsAtPath:tmplPath isDirectory:&isDirectory]){
		
		// index.html
		if(isDirectory){
			tmplPath = [tmplPath stringByAppendingPathComponent:@"index.html"];
		}
		
		NSString *html = [self processTemplate:tmplPath];
		NSData *htmlData = [html dataUsingEncoding: NSUTF8StringEncoding];
		return [[[HTTPDataResponse alloc] initWithData:htmlData] autorelease];
	}	   
	// Static files
	else if( [[NSFileManager defaultManager] fileExistsAtPath: [super filePathForURI: staticPath]] ){
		return [super httpResponseForMethod:method URI:staticPath];
	}
	// Not found
	else{
		NSLog(@"%@", tmplPath);
		return [super httpResponseForMethod:method URI:@"/404.html"];
	}
}

/**
 * Perform a 302 redirect
 */
- (void)redirect: (NSString *)url{
	NSLog(@"Redirect to %@", url);
	CFHTTPMessageRef response = CFHTTPMessageCreateResponse(kCFAllocatorDefault, 302, NULL, kCFHTTPVersion1_1);
	CFHTTPMessageSetHeaderFieldValue(response, CFSTR("Content-Length"), CFSTR("0"));
	CFHTTPMessageSetHeaderFieldValue(response, CFSTR("Location"), (CFStringRef)url);
	CFHTTPMessageSetHeaderFieldValue(response, CFSTR("Connection"), CFSTR("close"));
	
	NSData *responseData = [self preprocessResponse:response];
	[asyncSocket writeData:responseData withTimeout:30.0 tag:30L];
	
	CFRelease(response);
}
			
/**
 * Process template file
 */
- (NSString *)processTemplate: (NSString *)filePath{
	
	// Variables
	GanzbotQueue *queue = [ganzbot queue];
	NSArray *queueList = [queue getMessageQueue:NO];
	NSArray *historyList = [queue getMessageQueue:YES limit: 100];
	NSMutableDictionary *variables = [[[NSMutableDictionary alloc] init] autorelease];
	
	[variables setObject:queueList forKey:@"queue"]; 
	[variables setObject:historyList forKey:@"history"];
	
	// Process
	NSString *result = [tmplEngine processTemplateInFileAtPath:filePath withVariables:variables];
	
	return result;
}

/**
 * Retreives post data from the request and returns a NSDictionary object
 */
- (NSDictionary *)readPostData {
	
	NSString *postStr = nil;
	CFDataRef postData = CFHTTPMessageCopyBody(request);
	if(postData) {
		postStr = [[[NSString alloc] initWithData:(NSData *)postData encoding:NSUTF8StringEncoding] autorelease];
		CFRelease(postData);
	}
	
	return [self parseQuery:postStr];
}

/**
 * Parse a query string into a NSDictionary object
 */
- (NSDictionary *)parseQuery:(NSString *)queryString {
	NSMutableDictionary *data = [[NSMutableDictionary alloc] init];	
	
	if(!queryString){
		return data;
	}
	
	// Break up string
	NSArray *parts = [queryString componentsSeparatedByString:@"&"];
	for(NSInteger i = 0; i < [parts count]; i++){
		NSString *part = [parts objectAtIndex:i];
		NSArray *nameVal = [part componentsSeparatedByString:@"="];	
		
		// Name/value
		NSString *name = [nameVal objectAtIndex:0];
		NSString *value = @"";
		if([nameVal count] > 1){
			value = [nameVal objectAtIndex:1];
		}
		
		// Decode values
		name = [self urlDecode:name];
		value = [self urlDecode:value];
		
		[data setObject:value forKey:name];
	}
	
	return data;
}

/**
 * Decodes a URL string
 */
- (NSString *)urlDecode:(NSString *)value{
	
	// Replace '+' with space
	NSArray *spaces = [value componentsSeparatedByString:@"+"]; 
	value = [spaces componentsJoinedByString:@" "];
	
	// Decode '%' encodings & support double byte
	// Code yanked from http://lists.apple.com/archives/cocoa-dev/2005/Dec/msg01453.html
	value = [ value stringByReplacingPercentEscapesUsingEncoding: NSMacOSRomanStringEncoding ];
	const char *cstring = [ value cStringUsingEncoding: NSMacOSRomanStringEncoding ];
	value = [ [ NSString alloc ] initWithBytes: cstring length: strlen(cstring) encoding: NSShiftJISStringEncoding ];
	
	return value;
}


// ****************************************************************
// 
// Filters
// 
// ****************************************************************

- (NSArray *)filters {
	
	return [NSArray arrayWithObjects:
			@"escapeQuotes",
			nil];
}
- (NSObject *)filterInvoked:(NSString *)filter withArguments:(NSArray *)args onValue:(NSObject *)value{
	
	if( [filter isEqualToString:@"escapeQuotes"] ){
		NSString *valueStr = (NSString *)value;
		NSLog(@"Value: %@", valueStr);
		valueStr = [valueStr stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
		valueStr = [valueStr stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"];
		
		return valueStr;
	}
	
	return value;
}

// ****************************************************************
// 
// Methods below are all optional MGTemplateEngineDelegate methods.
// 
// ****************************************************************

- (void)templateEngine:(MGTemplateEngine *)engine blockStarted:(NSDictionary *)blockInfo {
	//NSLog(@"Started block %@", [blockInfo objectForKey:BLOCK_NAME_KEY]);
}


- (void)templateEngine:(MGTemplateEngine *)engine blockEnded:(NSDictionary *)blockInfo {
	//NSLog(@"Ended block %@", [blockInfo objectForKey:BLOCK_NAME_KEY]);
}


- (void)templateEngineFinishedProcessingTemplate:(MGTemplateEngine *)engine {
	//NSLog(@"Finished processing template.");
}

- (void)templateEngine:(MGTemplateEngine *)engine encounteredError:(NSError *)error isContinuing:(BOOL)continuing; {
	NSLog(@"Template error: %@", error);
}


// ****************************************************************
// 
// Methods below are all optional HTTPConnection methods.
// 
// ****************************************************************

/**
 * Overrides HTTPConnection's method
 **/
- (BOOL)supportsMethod:(NSString *)method atPath:(NSString *)path
{
	// Add support for POST
	if([method isEqualToString:@"POST"]){
		return YES;
	}
	
	return [super supportsMethod:method atPath:path];
}

/**
 * Overrides HTTPConnection's method
 **/
- (BOOL)expectsRequestBodyFromMethod:(NSString *)method atPath:(NSString *)relativePath
{
	// Inform HTTP server that we expect a body to accompany a POST request
	if([method isEqualToString:@"POST"])
		return YES;
	
	return [super expectsRequestBodyFromMethod:method atPath:relativePath];
}

/**
 * Overrides HTTPConnection's method
 **/
- (void)processDataChunk:(NSData *)postDataChunk
{
	BOOL result = CFHTTPMessageAppendBytes(request, [postDataChunk bytes], [postDataChunk length]);
	
	if(!result)
	{
		NSLog(@"Couldn't append bytes!");
	}
}


@end
