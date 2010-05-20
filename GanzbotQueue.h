//
//  GanzbotQueue.h
//  Ganzbot Controller
//
//  Created by Jeremy Gillick on 1/20/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface GanzbotQueue : NSObject {
	NSPersistentStoreCoordinator *persistentStoreCoordinator;
    NSManagedObjectModel *managedObjectModel;
	NSManagedObjectContext *managedObjectContext;
	
}

@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;

- (NSArray *) getMessageQueue: (BOOL)wasSpoken;
- (NSArray *) getMessageQueue: (BOOL)wasSpoken limit:(NSUInteger)useLimit;
- (void) emptyQueue: (BOOL)wasSpoken;
- (void)add: (NSString *)message voice:(NSString *)useVoice rate:(NSNumber *)useRate;

- (NSManagedObject *)getNextInQueue;
- (void)markAsSpoken: (NSManagedObject *)message;

@end
