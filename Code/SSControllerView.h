//
//  SecuritySpyView.h
//  SecuritySpy
//
//  Created by Milo on 31/07/2007.
//  Copyright (c) 2007, __MyCompanyName__. All rights reserved.
//

#import <ScreenSaver/ScreenSaver.h>
@class MBDeleteInterceptor;
@class SSCameraLayoutView;


@interface SSControllerView : ScreenSaverView 
{
	SSCameraLayoutView			*_cameraLayoutView;
	IBOutlet NSWindow			*_configureSheet;
	IBOutlet NSTabView			*_configureSheetTabView;
	IBOutlet NSTableView		*_serversTableView;
	IBOutlet NSArrayController	*_serversArrayController;
	IBOutlet NSTableView		*_camerasTableView;
	IBOutlet NSArrayController	*_camerasArrayController;
	IBOutlet NSTextField		*_addressTextField;
 IBOutlet NSButton *_sslCheck;
	MBDeleteInterceptor			*_deleteInterceptor;
}

- (NSMutableArray *)servers;

//  Configure Sheet.
- (IBAction)addServer:(id)sender;
- (IBAction)closeConfigureSheet:(id)sender;
@end
