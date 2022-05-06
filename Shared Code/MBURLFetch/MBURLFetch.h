//
//  MBURLFetch.h
//
//  Created by Milo on 13/04/2008.
//  Copyright 2008 Phantom Fish. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MBURLFetchQueue.h"
@protocol MBURLFetchDelegate;

typedef enum
{
	MBURLFetchQueuePriorityVeryLow  = -8,
	MBURLFetchQueuePriorityLow      = -4,
	MBURLFetchQueuePriorityNormal   = 0,
	MBURLFetchQueuePriorityHigh     = 4,
	MBURLFetchQueuePriorityVeryHigh = 8
} MBURLFetchQueuePriority;


@interface MBURLFetch : NSObject
{
	__weak id <MBURLFetchDelegate> _delegate;
	MBURLFetchQueuePriority        _queuePriority;
	id                             _userInfo;
	NSURLRequest                  *_request;
	NSURLConnection               *_connection;
	NSURLResponse                 *_response;
	NSMutableData                 *_data;
	BOOL                           _finished;
}

+ (id)fetchWithURLRequest:(NSURLRequest *)request;
- (id)initWithURLRequest:(NSURLRequest *)request;

- (void)start;
- (void)startInRunLoop:(NSRunLoop *)runLoop forMode:(NSString *)mode;    //  unschedules the connection from the default run loop and mode.
- (void)cancel;	       //  cancels an unfinished fetch and ensures no further messages are sent to the delegate - releasing the fetch will not suffice.

@property(nonatomic,assign) __weak id <MBURLFetchDelegate> delegate;
@property(nonatomic,assign) MBURLFetchQueuePriority queuePriority;
@property(nonatomic,retain) id userInfo;
@property(nonatomic,readonly) NSURLRequest *request;
@property(nonatomic,readonly) BOOL fetching;
@property(nonatomic,readonly) BOOL finished;       //  YES when the fetch was completed successfully, cancelled, failed, or could not be started.

@end


@protocol MBURLFetchDelegate <NSObject>

@required
- (void)fetch:(MBURLFetch *)fetch didReceiveResponse:(NSURLResponse *)response withData:(NSData *)data;       //  response == nil if the connection completed successfully but no response was received.

@optional
- (void)fetch:(MBURLFetch *)fetch willReceiveResponse:(NSURLResponse *)response currentDataLength:(NSUInteger)dataLength;      //  called multiple times as data is loaded.
- (BOOL)fetch:(MBURLFetch *)fetch shouldSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse;
- (BOOL)fetch:(MBURLFetch *)fetch shouldCacheResponse:(NSCachedURLResponse *)cachedResponse;
- (void)fetch:(MBURLFetch *)fetch didFailWithError:(NSError *)error;

@end



@interface NSMutableURLRequest (MBURLFetch)

//  a convenience method to create a request with custom headers and/or post data. Custom headers replace default headers with the same name. If postString is nil, a GET request is created. Pass 0 for timeoutInterval to use the default timeout of 60 seconds.
+ (id)requestWithURL:(NSURL *)url cachePolicy:(NSURLRequestCachePolicy)cachePolicy timeoutInterval:(NSTimeInterval)timeoutInterval customHeaders:(NSDictionary *)headers postData:(NSData *)postData;
+ (id)requestWithURL:(NSURL *)url cachePolicy:(NSURLRequestCachePolicy)cachePolicy timeoutInterval:(NSTimeInterval)timeoutInterval customHeaders:(NSDictionary *)headers postString:(NSString *)postString;

@end