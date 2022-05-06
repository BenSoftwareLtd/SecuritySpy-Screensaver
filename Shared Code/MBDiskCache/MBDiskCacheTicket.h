//
//  MBDiskCacheTicket.h
//  iSpy
//
//  Created by Milo on 29/04/2008.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface MBDiskCacheTicket : NSObject <NSCoding>
{
	NSNumber *_cacheID;
	NSDate *_datestamp;
}

@property(readonly, copy, nonatomic) NSDate *datestamp;
@end
