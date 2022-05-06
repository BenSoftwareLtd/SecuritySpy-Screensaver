//
//  MBDiskCacheTicket.m
//  iSpy
//
//  Created by Milo on 29/04/2008.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MBDiskCacheTicket.h"
#import "MBDiskCacheTicket+.h"


@implementation MBDiskCacheTicket

+ (NSMutableDictionary *)numberOfTicketsByCacheID;
{
	static NSMutableDictionary *cacheIDs = nil;
	if (cacheIDs == nil)
		cacheIDs = [[NSMutableDictionary alloc] initWithCapacity:10];
	return cacheIDs;
}

//  MBDiskCacheTicket ()
- (id)initWithCacheID:(NSNumber *)cacheID datestamp:(NSDate *)datestamp;
{
	if ([super init] == nil)
		return nil;
		
	NSParameterAssert(cacheID);
	NSParameterAssert(datestamp);
	_cacheID = [cacheID copy];
	self.datestamp = datestamp;

	NSNumber *newCount = [NSNumber numberWithInt:1 + [[[[self class] numberOfTicketsByCacheID] objectForKey:_cacheID] intValue]];
	[[[self class] numberOfTicketsByCacheID] setObject:newCount forKey:_cacheID];
		
	return self;
}

//  NSObject
- (id)init;
{
	return [self initWithCacheID:nil datestamp:nil];
}

//  NSObject
- (void)dealloc;
{
	NSNumber *newCount = [NSNumber numberWithInt:[[[[self class] numberOfTicketsByCacheID] objectForKey:_cacheID] intValue] - 1];
	NSParameterAssert([newCount intValue] >= 0);
	if ([newCount intValue] > 0)
		[[[self class] numberOfTicketsByCacheID] setObject:newCount forKey:_cacheID];
	else [[[self class] numberOfTicketsByCacheID] removeObjectForKey:_cacheID];
	
	[_cacheID release];
	self.datestamp = nil;
	[super dealloc];
}

//  NSObject
- (NSString *)description;
{
	return [self.cacheID description];
}

//  <NSCoding>
- (id)initWithCoder:(NSCoder *)coder;
{
	if ([super init] == nil)
		return nil;
	
	_cacheID = [[coder decodeObjectForKey:@"MBCacheID"] retain];
	self.datestamp = [coder decodeObjectForKey:@"MBDatestamp"];
	
	NSNumber *newCount = [NSNumber numberWithInt:1 + [[[[self class] numberOfTicketsByCacheID] objectForKey:_cacheID] intValue]];
	[[[self class] numberOfTicketsByCacheID] setObject:newCount forKey:_cacheID];
	
	return self;
}

//  <NSCoding>
- (void)encodeWithCoder:(NSCoder *)coder;
{
	[coder encodeObject:self.cacheID forKey:@"MBCacheID"];
	[coder encodeObject:self.datestamp forKey:@"MBDatestamp"];
}

@synthesize cacheID = _cacheID;
@synthesize datestamp = _datestamp;

@end
