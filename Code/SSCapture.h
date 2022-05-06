//
//  SSCapture.h
//  iSpy
//
//  Created by Milo on 03/04/2008.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SSItem.h"


@interface SSCapture : SSItem
{
	NSURL *_captureURL;
}

@property(retain, nonatomic) NSURL *captureURL;
@end
