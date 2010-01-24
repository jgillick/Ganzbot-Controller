//
//  GanzbotController.h
//  Ganzbot Controller
//
//  Created by Jeremy Gillick on 1/15/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//
#import <Cocoa/Cocoa.h>
#import "Ganzbot.h"
#import	"GanzbotQueue.h"
#import "GanzbotPrefs.h"
#import "GanzbotServer.h"

@interface GanzbotController : NSObject {
	
	IBOutlet NSTextField	*messageField;
	IBOutlet NSPopUpButton	*voicesList;
	IBOutlet NSPopUpButton	*speechRate;
	IBOutlet NSPopUpButton	*outputDeviceList;
	IBOutlet NSPopUpButton	*serialDeviceList;
	IBOutlet NSDrawer		*drawerPanel;
	IBOutlet NSTextField	*serverPortField;
	IBOutlet NSButton		*serverButton;
	IBOutlet NSTableView	*historyTable;
	
	IBOutlet NSArrayController *queueArray;
	IBOutlet NSArrayController *historyArray;
	
	Ganzbot *ganzbot;
	GanzbotQueue *queue;
	GanzbotServer *gserver;
	NSUserDefaults *prefs;
	
	NSManagedObjectContext *managedObjectContext;
}
@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;

- (IBAction)sayMessage:(id)sender;
- (IBAction)savePrefs: (id)sender;
- (IBAction)toggleServer: (id)sender;

@end
