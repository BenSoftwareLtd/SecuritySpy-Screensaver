//
//  MBURLFetchQueue.m
//
//  Created by Milo on 28/03/2008.
//  Copyright 2008 Phantom Fish. All rights reserved.
//

#import "MBURLFetchQueue.h"
#import "MBURLFetch.h"


@interface MBURLFetchQueue ()

- (void)processQueuedFetches;

@end


@implementation MBURLFetchQueue

+ (MBURLFetchQueue *)sharedFetchQueue;
{
	static MBURLFetchQueue *sharedFetchQueue = nil;
	if (sharedFetchQueue == nil)
		sharedFetchQueue = [[MBURLFetchQueue alloc] init];
	return sharedFetchQueue;
}

//  NSObject
- (id)init;
{
	self = [super init];
	if (self)
	{
		_fetches = [[NSMutableSet alloc] initWithCapacity:10];
		_queuedFetches = [[NSMutableArray alloc] initWithCapacity:10];
		_maxConcurrentConnections = 3;
	}
	return self;
}

//  NSObject
- (void)dealloc;
{
	for (MBURLFetch *fetch in _fetches)
	{
		[fetch removeObserver:self forKeyPath:@"finished"];
		[fetch cancel];
	}
	[_fetches release];
	[_queuedFetches release];
	[_userInfo release];
	[super dealloc];
}

//  NSObject
- (void)finalize;
{
	[self cancelAllFetches];
	[super finalize];
}

- (void)addFetch:(MBURLFetch *)fetch;
{
	if (fetch == nil || fetch.finished)
		[NSException raise:NSGenericException format:@""];
		
	if ([_fetches containsObject:fetch])
		return;

	[fetch addObserver:self forKeyPath:@"finished" options:0 context:NULL];
	[[self mutableSetValueForKey:@"fetches"] addObject:fetch];
	[_queuedFetches addObject:fetch];
	[self processQueuedFetches];
}

- (NSSet *)fetches;
{
	return _fetches;
}

- (void)cancelAllFetches;
{
	for (MBURLFetch *fetch in _fetches)
	{
		//  Must stop KVO before cancelling fetches, to avoid -observeValueForKeyPath starting fetches that are about to be cancelled.
		[fetch removeObserver:self forKeyPath:@"finished"];
		[fetch cancel];
	}
	[[self mutableSetValueForKey:@"fetches"] removeAllObjects];
	[_queuedFetches removeAllObjects];
	[self processQueuedFetches];
}

//  MBURLFetchQueue ()
- (void)processQueuedFetches;
{
	while ([_queuedFetches count] > 0 && [_fetches count] - [_queuedFetches count] < self.maxConcurrentConnections)
	{
		NSInteger i, chosenIndex = 0;
		for (i = 1; i < [_queuedFetches count]; i++)
		{
			if ([(MBURLFetch *)[_queuedFetches objectAtIndex:i] queuePriority] > [(MBURLFetch *)[_queuedFetches objectAtIndex:chosenIndex] queuePriority])
				chosenIndex = i;
		}
		
		MBURLFetch *fetch = [_queuedFetches objectAtIndex:chosenIndex];
		[_queuedFetches removeObjectAtIndex:chosenIndex];
		[fetch start];		//  may have side effects, so this is called at the end of the loop to make this method safe for reentry.
	}
	
	if (_willProcessQueuedFetches == YES)
		[NSObject cancelPreviousPerformRequestsWithTarget:self];
	_willProcessQueuedFetches = NO;
}

//  NSObject (NSKeyValueObserving)
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context;
{
	[object removeObserver:self forKeyPath:@"finished"];
	[[self mutableSetValueForKey:@"fetches"] removeObject:object];
	[_queuedFetches removeObjectIdenticalTo:object];
	//  Coalesce processing of queued fetches to allow the fetch delegate to queue new fetches, and to avoid starting a fetch that may be cancelled immediately. (It's common to cancel several fetches at once.)
	if (_willProcessQueuedFetches == NO)
	{
		[self performSelector:@selector(processQueuedFetches) withObject:nil afterDelay:0];
		_willProcessQueuedFetches = YES;
	}
}

- (void)setMaxConcurrentConnections:(NSInteger)count;
{
	_maxConcurrentConnections = count;
	[self processQueuedFetches];
}

@synthesize maxConcurrentConnections = _maxConcurrentConnections;
@synthesize userInfo = _userInfo;

@end
