//
//  SSCameraLayoutView.h
//  SecuritySpy
//
//  Created by Milo on 31/07/2007.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface SSCameraLayoutView : NSView
{
	NSMutableArray *_servers;
}

- (id)initWithFrame:(NSRect)frameRect servers:(NSArray *)servers;
@end
