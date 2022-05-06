//
//  MBDiskCacheTicket+.h
//  iSpy
//
//  Created by Milo on 29/04/2008.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface MBDiskCacheTicket ()

+ (NSMutableDictionary *)numberOfTicketsByCacheID;

- (id)initWithCacheID:(NSNumber *)cacheID datestamp:(NSDate *)datestamp;

@property(readonly, nonatomic) NSNumber *cacheID;
@property(readwrite, copy, nonatomic) NSDate *datestamp;
@end