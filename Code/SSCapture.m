//
//  SSCapture.m
//  iSpy
//
//  Created by Milo on 03/04/2008.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "SSCapture.h"


@implementation SSCapture

//  NSObject
- (void)dealloc;
{
	self.captureURL = nil;
	[super dealloc];
}

//  <NSCoding>
- (id)initWithCoder:(NSCoder *)coder;
{
	if ([super initWithCoder:coder] == nil)
		return nil;
	
	self.captureURL = [coder decodeObjectForKey:@"SSCaptureURL"];
	
	return self;
}

//  <NSCoding>
- (void)encodeWithCoder:(NSCoder *)coder;
{
	[super encodeWithCoder:coder];
	
	[coder encodeObject:self.captureURL forKey:@"SSCaptureURL"];
}

@synthesize captureURL = _captureURL;

@end
