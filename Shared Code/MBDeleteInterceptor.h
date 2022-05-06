//
//  MBDeleteInterceptor.h
//  Request
//
//  Original version by Dustin Voss
//
//  Created by Milo on 15/05/2007.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MBDeleteInterceptor : NSResponder
{
	id	_target;
	SEL	_selector;
	id	_previousResponder;
}

//  Selector should be of the form handleDelete:(id)sender
- (id)initWithSelector:(SEL)selector onTarget:(id)target above:(NSResponder *)responder;	//  Designated initialiser. Raises an exception if selector is NULL, target is nil or responder is nil.

- (void)invalidate;		//  Removes the delete interceptor from the responder chain. Automatically called in -dealloc.
@end
