//
//  MBDeleteInterceptor.m
//  Request
//
//  Created by Milo on 15/05/2007.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "MBDeleteInterceptor.h"


@implementation MBDeleteInterceptor

- (id)initWithSelector:(SEL)selector onTarget:(id)target above:(NSResponder *)responder;
{
	if ([super init] == nil)
		return nil;
		
	if (selector == NULL || target == nil || responder == nil)
	{
		[self release];
		[NSException raise:NSInvalidArgumentException format:@""];
		return nil;
	}
		
	_selector = selector;
	_target = target;
	_previousResponder = [responder retain];
	
	[self setNextResponder:[responder nextResponder]];
	[responder setNextResponder:self];
	
	return self;
}

//  NSObject
- (id)init;
{
	return [self initWithSelector:NULL onTarget:nil above:nil];
}

//  NSObject
- (void)dealloc;
{
	[self invalidate];
	[_previousResponder release];
	
	[super dealloc];
}

//  NSResponder
- (void)keyDown:(NSEvent *)theEvent;
{
	[self interpretKeyEvents:[NSArray arrayWithObject:theEvent]];
}

//  NSResponder
- (void)deleteBackward:(id)sender;
{
	[_target performSelector:_selector withObject:sender];
}

//  NSResponder
- (void)deleteForward:(id)sender;
{
	[_target performSelector:_selector withObject:sender];
}

- (void)invalidate;
{
	if ([self nextResponder] == nil)
		return;
		
	[_previousResponder setNextResponder:[self nextResponder]];
	[self setNextResponder:nil];
}

@end
