//
//  SSCamera.h
//  SecuritySpy
//
//  Concrete subclass representing a camera in SecuritySpy.
//
//  Created by Milo on 31/07/2007.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SSItem.h"


@interface SSCamera : SSItem
{
	BOOL	_hidden;
}

@property(readwrite, nonatomic) BOOL hidden;
@end