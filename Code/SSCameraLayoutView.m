//
//  SSCameraLayoutView.m
//  SecuritySpy
//
//  Created by Milo on 31/07/2007.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "SSCameraLayoutView.h"
#import "SSServer.h"
#import "SSCamera.h"
#import "DLog.h"


@interface SSCameraLayoutView () <SSServerNotifications>

- (void)layoutCameras;
@end


#pragma mark -
@implementation SSCameraLayoutView

- (id)initWithFrame:(NSRect)frameRect servers:(NSArray *)servers;
{
	if ([super initWithFrame:frameRect] == nil)
		return nil;
	
	NSParameterAssert(servers);
	_servers = [servers mutableCopy];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(serverDidLoadCameras:) name:SSServerDidLoadCamerasNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(serverConnectionDidFail:) name:SSServerConnectionDidFailNotification object:nil];
	
	for (SSServer *server in _servers)
	{
		[server addObserver:self forKeyPath:@"cameras" options:0 context:NULL];
		[server loadCameras];
	}
	
	[self layoutCameras];
	
	return self;
}

//  NSView
- (id)initWithFrame:(NSRect)frameRect;
{
	return [self initWithFrame:frameRect servers:nil];
}

//  NSObject
- (void)dealloc;
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	for (SSServer *server in _servers)
		[server removeObserver:self forKeyPath:@"cameras"];
	[_servers release];
	
	[super dealloc];
}

//  NSObject (NSKeyValueObserving)
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context;
{
	[self layoutCameras];
}

//  NSView
- (BOOL)isFlipped;
{
	return YES;
}

- (void)layoutCameras;
{
	[self setSubviews:[NSArray array]];
	
	NSArray *cameras = [[_servers valueForKeyPath:@"@unionOfArrays.cameras"] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"hidden == NO"]];
	if ([cameras count] == 0)
		return;
	
	//  Determine the most appropriate aspect ratio.
	CGSize aspectRatio = CGSizeMake(0, 0);
	for (SSCamera *camera in cameras)
	{
		aspectRatio.width += camera.nativeResolution.width;
		aspectRatio.height += camera.nativeResolution.height;
	}
	if (aspectRatio.width / aspectRatio.height > (4.0/3.0 + 16.0/9.0) / 2)	//  The average aspect ratio is closer to 16:9 than 4:3.
		aspectRatio = CGSizeMake(16, 9);
	else aspectRatio = CGSizeMake(4, 3);
	
	//  Calculate the number of rows and columnns needed.
	unsigned rows = ceil(sqrt((aspectRatio.width * [cameras count] * [self bounds].size.height) / (aspectRatio.height * [self bounds].size.width)));	//  Sized to fit screen height.
	unsigned columns = ceil(sqrt((aspectRatio.height * [cameras count] * [self bounds].size.width) / (aspectRatio.width * [self bounds].size.height)));	//  Sized to fit screen width.
	if ([self bounds].size.width * aspectRatio.height / columns > [self bounds].size.height * aspectRatio.width / rows)		//  Sizing to fit width will result in larger views.
		rows = ceil(((CGFloat)[cameras count] / (CGFloat)columns));
	else columns = ceil(((CGFloat)[cameras count] / (CGFloat)rows));
	
	// Calculate the the size of each view in points and in pixels, the number of views per row, and the offset to centre the display.
	CGSize viewSize = CGSizeMake([self bounds].size.width / columns, [self bounds].size.height / rows);
	if (viewSize.width / viewSize.height > aspectRatio.width / aspectRatio.height)
		viewSize.width = viewSize.height * aspectRatio.width / aspectRatio.height;
	else viewSize.height = viewSize.width * aspectRatio.height / aspectRatio.width;
	CGPoint displayOffset = CGPointMake(([self bounds].size.width - (viewSize.width * columns)) / 2, ([self bounds].size.height - (viewSize.height * rows)) / 2);
	
	unsigned i;
	for (i = 0; i < [cameras count]; i++)
	{
		[[cameras objectAtIndex:i] loadImageWithRequiredDisplaySize:viewSize];
		
		//  Create the views.
		NSImageView *view = [[NSImageView alloc] initWithFrame:NSMakeRect(displayOffset.x + (i % columns) * viewSize.width, displayOffset.y + (i / columns) * viewSize.height, viewSize.width, viewSize.height)];
		[view setImageFrameStyle:NSImageFrameNone];
		[view setImageScaling:NSScaleToFit];
		[view bind:@"value" toObject:[cameras objectAtIndex:i] withKeyPath:@"image" options:nil];
		[self addSubview:view];
		[view release];
	}
}

//  <SSServerNotifications>
- (void)serverDidLoadCameras:(NSNotification *)notification;
{
	if ([_servers containsObject:[notification object]])
		[self layoutCameras];
}

//  <SSServerNotifications>
- (void)serverConnectionDidFail:(NSNotification *)notification;
{
	if ([_servers containsObject:[notification object]])
	{
		[[notification object] removeObserver:self forKeyPath:@"cameras"];
		[_servers removeObject:[notification object]];
		[self layoutCameras];
	}
}

@end