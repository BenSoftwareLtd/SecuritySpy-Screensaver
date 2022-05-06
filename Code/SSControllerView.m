//
//  SecuritySpyView.m
//  SecuritySpy
//
//  Created by Milo on 31/07/2007.
//  Copyright (c) 2007, __MyCompanyName__. All rights reserved.
//

#import "SSControllerView.h"
#import "SSCameraLayoutView.h"
#import "SSServer.h"
#import "SSCamera.h"
#import "NSData+MBObfuscate.h"
#import "MBDeleteInterceptor.h"
#import "NSMutableArray+MBReordering.h"
#import "DLog.h"

static NSMutableArray *sharedServers = nil;
NSString *SSServerDataArray = @"SSServerDataArray2";					//  NSUserDefaults key.
NSString *SSServersTableViewDataType = @"SSServersTableViewDataType";	//  Drag-and-drop.


@interface SSControllerView ()

- (void)setServers:(NSMutableArray *)servers;
@end


#pragma mark -
@interface ScreenSaverDefaults (SSControllerView)

+ (ScreenSaverDefaults *)securitySpyScreenSaverDefaults;

- (NSMutableArray *)readServers;
- (void)writeServers:(NSArray *)servers;
@end


#pragma mark -
@implementation SSControllerView

//  NSObject
+ (void)initialize;
{	
	//  Register the default User Defaults.
	NSMutableDictionary *defaults = [NSMutableDictionary dictionaryWithCapacity:1];
	
	SSServer *server = [[[SSServer alloc] init] autorelease];
	server.address = @"localhost";
	[defaults setObject:[NSArray arrayWithObject:[NSKeyedArchiver archivedDataWithRootObject:server]] forKey:SSServerDataArray];
	
	[[ScreenSaverDefaults securitySpyScreenSaverDefaults] registerDefaults:defaults];
}

/*
+ (BOOL)respondsToSelector:(SEL)selector;
{
	DLog(@"%@", NSStringFromSelector(selector));
	return [super respondsToSelector:selector];
}

- (BOOL)respondsToSelector:(SEL)selector;
{
	DLog(@"%@", NSStringFromSelector(selector));
	return [super respondsToSelector:selector];
}
*/

//  ScreenSaverView
- (id)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview
{
    if ([super initWithFrame:frame isPreview:isPreview] == nil)
		return nil;
	
	[self setAnimationTimeInterval:1000];		//  We don't want to animate at all!
	
	if ([self servers] == nil)
		[self setServers:[[ScreenSaverDefaults securitySpyScreenSaverDefaults] readServers]];
	
    return self;
}

//  NSObject
- (void)dealloc;
{
	[_deleteInterceptor release];
	
	[super dealloc];
}

//  ScreenSaverView
- (void)startAnimation
{
	[_cameraLayoutView removeFromSuperview];
	_cameraLayoutView = [[SSCameraLayoutView alloc] initWithFrame:[self bounds] servers:[self servers]];
	[self addSubview:_cameraLayoutView];
	[_cameraLayoutView release];
	
    [super startAnimation];
}

//  ScreenSaverView
- (void)stopAnimation
{
	[_cameraLayoutView removeFromSuperview];
	_cameraLayoutView = nil;

	for (SSServer *server in [self servers])
	{
		for (SSCamera *camera in server.cameras)
			[camera stopLoadingImage:YES];
	}

    [super stopAnimation];
}

- (void)drawRect:(NSRect)rect
{
    [super drawRect:rect];
}

- (void)animateOneFrame
{
    return;
}

//  NSView
- (BOOL)isOpaque;
{
	return YES;
}

//  NSResponder
- (void)mouseMoved:(NSEvent *)theEvent;
{
	#ifndef MB_DEBUG
	[super mouseMoved:theEvent];
	#endif
}

//  NSResponder
- (void)keyDown:(NSEvent *)theEvent;
{
	#ifndef MB_DEBUG
	[super keyDown:theEvent];
	#endif
}

- (NSMutableArray *)servers;
{
	return sharedServers;
}

//  SSControllerView ()
- (void)setServers:(NSMutableArray *)servers;
{
	if (servers == sharedServers)
		return;
	[sharedServers release];
	sharedServers = [servers retain];
}

#pragma mark Configure Sheet

//  ScreenSaverView
- (BOOL)hasConfigureSheet
{
    return YES;
}

//  ScreenSaverView
- (NSWindow*)configureSheet
{
    if (_configureSheet == nil)
	{
		[NSBundle loadNibNamed:@"ConfigureSheet" owner:self];
		_deleteInterceptor = [[MBDeleteInterceptor alloc] initWithSelector:@selector(remove:) onTarget:_serversArrayController above:_serversTableView];
		[_serversTableView registerForDraggedTypes:[NSArray arrayWithObject:SSServersTableViewDataType]];
	}
	
	for (SSCamera *camera in [_camerasArrayController arrangedObjects])
		[camera stopLoadingImage:YES];
	
	if ([_configureSheetTabView indexOfTabViewItem:[_configureSheetTabView selectedTabViewItem]] == 1)		//  The Cameras tab is selected.
	{
		[[[_camerasArrayController selectedObjects] lastObject] loadImageWithRequiredDisplaySize:CGSizeMake(240,180)];
		[[self servers] makeObjectsPerformSelector:@selector(loadCameras)];
	}
		
	return _configureSheet;
}

//  NSObject (NSTabViewDelegate)
- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem;
{
	//  We turn on the binding for the camera array controller only when we need to display the list of cameras, to avoid constantly attempting to connect to a server whilst editing its properties.

	if ([tabView indexOfTabViewItem:tabViewItem] == 1)		//  The Cameras tab was selected.
	{
		[[self servers] makeObjectsPerformSelector:@selector(loadCameras)];
		[[[_camerasArrayController selectedObjects] lastObject] loadImageWithRequiredDisplaySize:CGSizeMake(240,180)];
	}
	else	//  The Servers tab was selected.
		[[[_camerasArrayController selectedObjects] lastObject] stopLoadingImage:NO];
}

- (IBAction)addServer:(id)sender;
{
	[_serversArrayController add:self];
	[_addressTextField selectText:self];
}

//  NSObject(NSTableDataSource)
- (BOOL)tableView:(NSTableView *)tableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pasteboard;
{
    [pasteboard declareTypes:[NSArray arrayWithObject:SSServersTableViewDataType] owner:self];
    [pasteboard setData:[NSKeyedArchiver archivedDataWithRootObject:rowIndexes] forType:SSServersTableViewDataType];
    return YES;
}

//  NSObject(NSTableDataSource)
- (NSDragOperation)tableView:(NSTableView*)tableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)dropOperation;
{
	if (dropOperation == NSTableViewDropOn)
		[_serversTableView setDropRow:row dropOperation:NSTableViewDropAbove];
	return NSDragOperationEvery;
}

//  NSObject(NSTableDataSource)
- (BOOL)tableView:(NSTableView *)tableView acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)dropOperation;
{
	[[self mutableArrayValueForKey:@"servers"] moveObjectsFromIndexSet:[NSKeyedUnarchiver unarchiveObjectWithData:[[info draggingPasteboard] dataForType:SSServersTableViewDataType]] toIndex:row];
	return YES;
}

//  NSObject(NSTableViewDelegate)
- (void)tableViewSelectionDidChange:(NSNotification *)notification;
{
	//  A new camera was selected for preview, so close the connection to the old camera and open the connection to the new camera.
	for (SSCamera *camera in [_camerasArrayController arrangedObjects])
		[camera stopLoadingImage:NO];
	[[[_camerasArrayController selectedObjects] lastObject] loadImageWithRequiredDisplaySize:CGSizeMake(240,180)];
}

- (IBAction)closeConfigureSheet:(id)sender;
{
	[_serversArrayController commitEditing];
	for (SSCamera *camera in [_camerasArrayController arrangedObjects])
		[camera stopLoadingImage:YES];
	
	if ([sender tag] == 1)	//  OK rather than Cancel.
		[[ScreenSaverDefaults securitySpyScreenSaverDefaults] writeServers:[self servers]];
		
	else [self setServers:[[ScreenSaverDefaults securitySpyScreenSaverDefaults] readServers]];
	
	[NSApp endSheet:_configureSheet];
}

@end


#pragma mark -
@implementation ScreenSaverDefaults (SSControllerView)

+ (ScreenSaverDefaults *)securitySpyScreenSaverDefaults;
{
	return [ScreenSaverDefaults defaultsForModuleWithName:[[NSBundle bundleForClass:[SSControllerView class]] bundleIdentifier]];
}

- (NSMutableArray *)readServers;
{
	NSMutableArray *newServers = [NSMutableArray array];

	if ([self objectForKey:@"SSServerPropertiesArray"] != nil)		//  Import data from version 1.0 defaults.
	{
		[NSData setEndianDependentObfuscation:YES];
		for (NSDictionary *properties in [self objectForKey:@"SSServerPropertiesArray"])
		{
			SSServer *server = [[SSServer alloc] init];
			if ([properties objectForKey:@"SSAddressServerProperty"] != nil)
				server.address = [properties objectForKey:@"SSAddressServerProperty"];
			if ([properties objectForKey:@"SSPortServerProperty"] != nil && [[properties objectForKey:@"SSPortServerProperty"] unsignedIntValue] != 8000)
				server.address = [server.address stringByAppendingFormat:@":%@", [properties objectForKey:@"SSPortServerProperty"]];
			if ([properties objectForKey:@"SSUsernameServerProperty"] != nil)
				server.username = [properties objectForKey:@"SSUsernameServerProperty"];
			if ([properties objectForKey:@"SSPasswordServerProperty"] != nil)
				server.password = [[[NSString alloc] initWithData:[[properties objectForKey:@"SSPasswordServerProperty"] dataObfuscatedWithKey:82031280] encoding:NSUnicodeStringEncoding] autorelease];
			if ([properties objectForKey:@"SSFrameRateServerProperty"] != nil)
				server.frameRate = [properties objectForKey:@"SSFrameRateServerProperty"];
			[newServers addObject:server];
			[server release];
		}
		
		[NSData setEndianDependentObfuscation:NO];
		[self removeObjectForKey:@"SSServerPropertiesArray"];
		[self writeServers:newServers];
	}
	else if ([self objectForKey:@"SSServerDataArray"] != nil)		//  Import data from version 1.1 defaults.
	{
		[NSData setEndianDependentObfuscation:YES];
		for (NSData *data in [self objectForKey:@"SSServerDataArray"])
			[newServers addObject:[NSKeyedUnarchiver unarchiveObjectWithData:data]];
		[NSData setEndianDependentObfuscation:NO];
		[self removeObjectForKey:@"SSServerDataArray"];
		[self writeServers:newServers];
	}
	else
	{
		for (NSData *data in [self objectForKey:SSServerDataArray])
			[newServers addObject:[NSKeyedUnarchiver unarchiveObjectWithData:data]];
	}
	
	return newServers;
}

- (void)writeServers:(NSArray *)servers;
{
	if (servers == nil)
		return;
	
	NSMutableArray *serverData = [NSMutableArray arrayWithCapacity:[servers count]];
	
	for (SSServer *server in servers)
		[serverData addObject:[NSKeyedArchiver archivedDataWithRootObject:server]];
	
	[self setObject:serverData forKey:SSServerDataArray];
	[self synchronize];
}

@end














