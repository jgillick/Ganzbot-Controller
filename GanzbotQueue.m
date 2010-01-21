//
//  GanzbotQueue.m
//  Ganzbot Controller
//
//  Created by Jeremy Gillick on 1/20/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "GanzbotQueue.h"


@implementation GanzbotQueue

- (id)init {
	self = [super init];
	
	if(self){
		[self managedObjectModel];
		[self managedObjectContext];
	}
	
	return self;
}

/**
 * Add a message to the queue
 */
- (void)add:(NSString *)message{
	NSManagedObject *messageEntity = nil; 
	
	messageEntity = [NSEntityDescription insertNewObjectForEntityForName: @"Message" inManagedObjectContext: [self managedObjectContext]]; 
	[messageEntity setValue: message forKey: @"text"];
	[messageEntity setValue: [NSDate date] forKey: @"created_on"];
	
	if ([[self managedObjectContext] commitEditing]) {
        NSError *error = nil;
        [[self managedObjectContext] save:&error];
	}
}

/**
 * Get message queue.
 */
- (NSArray *) getMessageQueue: (BOOL)wasSpoken{
		

	NSDictionary		*entities = [[self managedObjectModel] entitiesByName]; 
	NSEntityDescription	*entity = [entities valueForKey:@"Message"];
	
	NSPredicate *predicate; 
	predicate = [NSPredicate predicateWithFormat:@"was_spoken == %i", wasSpoken]; 
	
	NSSortDescriptor	*sort = [[NSSortDescriptor alloc] initWithKey:@"created_on" ascending:YES];
	NSArray				*sortDescriptors = [NSArray arrayWithObject: sort]; 
	
	NSFetchRequest *fetch = [[NSFetchRequest alloc] init]; 
	[fetch setEntity: entity]; 
	[fetch setPredicate: predicate]; 
	[fetch setSortDescriptors: sortDescriptors]; 
	
	NSArray *results = [[self managedObjectContext] executeFetchRequest:fetch error:nil]; 
	
	[sort release]; 
	[fetch release]; 
	
	return results;
}


/**
 Returns the support directory for the application, used to store the Core Data
 store file.  This code uses a directory named "Core_Data_App" for
 the content, either in the NSApplicationSupportDirectory location or (if the
 former cannot be found), the system's temporary directory.
 */

- (NSString *)applicationSupportDirectory {
	
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : NSTemporaryDirectory();
    return [basePath stringByAppendingPathComponent:@"Ganzbot_Controller"];
}


/**
 Creates, retains, and returns the managed object model for the application 
 by merging all of the models found in the application bundle.
 */

- (NSManagedObjectModel *)managedObjectModel {
	
    if (managedObjectModel) return managedObjectModel;
	
    managedObjectModel = [[NSManagedObjectModel mergedModelFromBundles:nil] retain];    
    return managedObjectModel;
}


/**
 Returns the persistent store coordinator for the application.  This 
 implementation will create and return a coordinator, having added the 
 store for the application to it.  (The directory for the store is created, 
 if necessary.)
 */

- (NSPersistentStoreCoordinator *) persistentStoreCoordinator {
	
    if (persistentStoreCoordinator) return persistentStoreCoordinator;
	
    NSManagedObjectModel *mom = [self managedObjectModel];
    if (!mom) {
        NSAssert(NO, @"Managed object model is nil");
        NSLog(@"%@:%s No model to generate a store from", [self class], _cmd);
        return nil;
    }
	
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *applicationSupportDirectory = [self applicationSupportDirectory];
    NSError *error = nil;
    
    if ( ![fileManager fileExistsAtPath:applicationSupportDirectory isDirectory:NULL] ) {
		if (![fileManager createDirectoryAtPath:applicationSupportDirectory withIntermediateDirectories:NO attributes:nil error:&error]) {
            NSAssert(NO, ([NSString stringWithFormat:@"Failed to create App Support directory %@ : %@", applicationSupportDirectory,error]));
            NSLog(@"Error creating application support directory at %@ : %@",applicationSupportDirectory,error);
            return nil;
		}
    }
    
    NSURL *url = [NSURL fileURLWithPath: [applicationSupportDirectory stringByAppendingPathComponent: @"storedata"]];
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: mom];
    if (![persistentStoreCoordinator addPersistentStoreWithType:NSXMLStoreType 
												  configuration:nil 
															URL:url 
														options:nil 
														  error:&error]){
        [[NSApplication sharedApplication] presentError:error];
        [persistentStoreCoordinator release], persistentStoreCoordinator = nil;
        return nil;
    }    
	
    return persistentStoreCoordinator;
}

/**
 Returns the managed object context for the application (which is already
 bound to the persistent store coordinator for the application.) 
 */

- (NSManagedObjectContext *) managedObjectContext {
	
    if (managedObjectContext) return managedObjectContext;
	
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setValue:@"Failed to initialize the store" forKey:NSLocalizedDescriptionKey];
        [dict setValue:@"There was an error building up the data file." forKey:NSLocalizedFailureReasonErrorKey];
        NSError *error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    managedObjectContext = [[NSManagedObjectContext alloc] init];
    [managedObjectContext setPersistentStoreCoordinator: coordinator];
	
    return managedObjectContext;
}


/**
 Implementation of dealloc, to release the retained variables.
 */

- (void)dealloc {
	
    [managedObjectContext release];
    [persistentStoreCoordinator release];
    [managedObjectModel release];
	
    [super dealloc];
}


@end
