//
//  GanzbotController.h
//  Ganzbot Controller
//
//  Created by Jeremy Gillick on 1/15/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//
#import <Cocoa/Cocoa.h>
#import "Ganzbot.h"
#import "GanzbotPrefs.h"

@interface GanzbotController : NSObject {
	
	IBOutlet NSTextField	*messageField;
	IBOutlet NSPopUpButton	*voicesList;
	IBOutlet NSPopUpButton	*speechRate;
	IBOutlet NSPopUpButton	*outputDeviceList;
	IBOutlet NSPopUpButton	*serialDeviceList;
	IBOutlet NSDrawer		*drawerPanel;
	IBOutlet NSTextField	*serverPortField;
	IBOutlet NSRuleEditor	*queueList;
	IBOutlet NSTableView	*history;
	
	Ganzbot *ganzbot;
	NSUserDefaults *prefs;
}

- (IBAction)sayMessage:(id)sender;
- (IBAction)savePrefs: (id)sender;
- (IBAction)toggleServer: (id)sender;

@end
