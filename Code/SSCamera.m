//
//  SSCamera.m
//  SecuritySpy
//
//  Created by Milo on 31/07/2007.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "SSCamera.h"
#import "SSItem.h"
#import "SSItem+.h"
#import "SSServer.h"
#import "SSServer+.h"
#import "MBDiskCache.h"
#import "DLog.h"


@implementation SSCamera

//  <NSCoding>
- (id)initWithCoder:(NSCoder *)coder;
{
	if ([super initWithCoder:coder] == nil)
		return nil;
	
	self.hidden = [coder decodeBoolForKey:@"SSIsHidden"];
	
	return self;
}

//  <NSCoding>
- (void)encodeWithCoder:(NSCoder *)coder;
{
	[super encodeWithCoder:coder];
	
	[coder encodeBool:self.hidden forKey:@"SSIsHidden"];
}

//  SSItem ()
- (NSURL *)imageURL;
{
	return [NSURL URLWithString:[NSString stringWithFormat:@"++video?cameraNum=%@&quality=50&req_fps=%u", self.inputNumber, ([self.server.frameRate unsignedIntValue] != 0 ? [self.server.frameRate unsignedIntValue] : 1)] relativeToURL:[self.server url]];
}

//  SSItem ()
- (NSURL *)previewURL;
{
	return [NSURL URLWithString:[NSString stringWithFormat:@"++image?cameraNum=%@&quality=75", self.inputNumber] relativeToURL:[self.server url]];
}

//  SSItem ()
- (BOOL)shouldReloadPreview;
{
	if (self.previewCacheTicket.datestamp == nil || [self.previewCacheTicket.datestamp timeIntervalSinceNow] < -(60 * 60))		//  The preview was cached more than an hour ago.
		return YES;		
	else return NO;
}

@synthesize hidden = _hidden;

@end