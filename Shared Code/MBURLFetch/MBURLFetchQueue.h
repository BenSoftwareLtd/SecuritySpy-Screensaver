//
//  MBURLFetchQueue.h
//
//  Created by Milo on 28/03/2008.
//  Copyright 2008 Phantom Fish. All rights reserved.
//

#import <Foundation/Foundation.h>
@class MBURLFetch;


@interface MBURLFetchQueue : NSObject
{
	NSMutableSet   *_fetches;
	NSMutableArray *_queuedFetches;
	BOOL            _willProcessQueuedFetches;
	NSInteger       _maxConcurrentConnections;
	id              _userInfo;
}

+ (MBURLFetchQueue *)sharedFetchQueue;

- (void)addFetch:(MBURLFetch *)fetch;
- (NSSet *)fetches;          //  KVO compliant.
- (void)cancelAllFetches;

@property(nonatomic) NSInteger maxConcurrentConnections;		//  default is 3. Set to 0 to suspend the queue.
@property(nonatomic,retain) id userInfo;

@end