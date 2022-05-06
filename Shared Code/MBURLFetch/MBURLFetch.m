//
//  MBURLFetch.m
//
//  Created by Milo on 13/04/2008.
//  Copyright 2008 Phantom Fish. All rights reserved.
//

#import "MBURLFetch.h"


@implementation MBURLFetch

+ (id)fetchWithURLRequest:(NSURLRequest *)request;
{
	return [[[self alloc] initWithURLRequest:request] autorelease];
}

- (id)initWithURLRequest:(NSURLRequest *)request;
{
	self = [super init];
	if (self)
	{
		if (!request)
			[NSException raise:NSInvalidArgumentException format:@""];
		_request = [request copy];
	}
	return self;
}

//  NSObject
- (id)init;
{
	return [self initWithURLRequest:nil];
}

//  NSObject
- (void)dealloc;
{
	[_userInfo release];
	[_request release];
	[_connection cancel];
	[_connection release];
	[_response release];
	[_data release];
	[super dealloc];
}

//  NSObject
- (void)finalize;
{
	[_connection cancel];
	[super finalize];
}

//  NSObject
- (NSString *)description;
{
	return [NSString stringWithFormat:@"MBURLFetch: %@", [[self.request URL] absoluteString]];
}

- (void)start;
{
	if (self.finished)
		[NSException raise:NSGenericException format:@""];
	if (self.fetching)
		return;
	[self willChangeValueForKey:@"fetching"];
	_connection = [[NSURLConnection alloc] initWithRequest:self.request delegate:self];
	[self didChangeValueForKey:@"fetching"];
	if (self.fetching == NO)
		[self cancel];
}

- (void)startInRunLoop:(NSRunLoop *)runLoop forMode:(NSString *)mode;
{
	if (self.finished)
		[NSException raise:NSGenericException format:@""];
	if (self.fetching)
		return;
	[self willChangeValueForKey:@"fetching"];
	_connection = [[NSURLConnection alloc] initWithRequest:self.request delegate:self startImmediately:NO];
	[_connection unscheduleFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[_connection scheduleInRunLoop:runLoop forMode:mode];
	[_connection start];
	[self didChangeValueForKey:@"fetching"];
	if (self.fetching == NO)
		[self cancel];
}

- (void)cancel;
{
	[[self retain] autorelease];	//  we must ensure that we aren't released to the point of deallocation by NSURLConnection or MBURLFetchQueue during this method.
	if (self.fetching)
	{
		[_connection cancel];
		[self willChangeValueForKey:@"fetching"];
		[_connection release];
		_connection = nil;
		[self didChangeValueForKey:@"fetching"];
		[_response release];
		_response = nil;
		[_data release];
		_data = nil;
	}
	if (self.finished == NO)
	{
		[self willChangeValueForKey:@"finished"];
		_finished = YES;
		[self didChangeValueForKey:@"finished"];
	}
}

- (BOOL)fetching;
{
	return (_connection != nil);
}

//  NSObject (NSURLConnectionDelegate)
- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse;
{
	if ([self.delegate respondsToSelector:@selector(fetch:shouldSendRequest:redirectResponse:)])
		return ([self.delegate fetch:self shouldSendRequest:request redirectResponse:redirectResponse] ? request : nil);
	else return request;
}

//  NSObject (NSURLConnectionDelegate)
- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse;
{
	if ([self.delegate respondsToSelector:@selector(fetch:shouldCacheResponse:)])
		return ([self.delegate fetch:self shouldCacheResponse:cachedResponse] ? cachedResponse : nil);
	else return cachedResponse;
}

//  NSObject (NSURLConnectionDelegate)
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response;
{	
	if (_response)
	{
		[[self retain] autorelease];     //  ensures we aren't deallocated during the first call to the delegate.
		NSURLResponse *oldResponse = [_response retain];
		NSMutableData *oldData = [_data retain];
		[self.delegate fetch:self didReceiveResponse:oldResponse withData:(oldData ? oldData : [NSData data])];
		[oldResponse release];
		[oldData release];
		if (self.finished)
			return;
	}
	[_response release];
	_response = [response retain];
	[_data release];
	_data = nil;
	if ([self.delegate respondsToSelector:@selector(fetch:willReceiveResponse:currentDataLength:)])
		[self.delegate fetch:self willReceiveResponse:response currentDataLength:0];
}

//  NSObject (NSURLConnectionDelegate)
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data;
{
	if (!_data)
		_data = [data mutableCopy];
	else [_data	appendData:data];
	if ([self.delegate respondsToSelector:@selector(fetch:willReceiveResponse:currentDataLength:)])
	{
		NSURLResponse *response = [_response retain];
		[self.delegate fetch:self willReceiveResponse:response currentDataLength:[_data length]];
		[response release];
	}
}

//  NSObject (NSURLConnectionDelegate)
- (void)connectionDidFinishLoading:(NSURLConnection *)connection;
{	
	NSURLResponse *response = [_response retain];
	NSMutableData *data = [_data retain];
	[self cancel];
	[self.delegate fetch:self didReceiveResponse:response withData:(data ? data : [NSData data])];
	[response release];
	[data release];
}

//  NSObject (NSURLConnectionDelegate)
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error;
{
	[self cancel];
	if ([self.delegate respondsToSelector:@selector(fetch:didFailWithError:)])
		[self.delegate fetch:self didFailWithError:error];
}

@synthesize delegate = _delegate;
@synthesize queuePriority = _queuePriority;
@synthesize userInfo = _userInfo;
@synthesize request = _request;
@synthesize finished = _finished;

@end


@implementation NSMutableURLRequest (MBURLFetch)

+ (id)requestWithURL:(NSURL *)url cachePolicy:(NSURLRequestCachePolicy)cachePolicy timeoutInterval:(NSTimeInterval)timeoutInterval customHeaders:(NSDictionary *)headers postData:(NSData *)postData;
{
	NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] initWithURL:url cachePolicy:cachePolicy timeoutInterval:(timeoutInterval > 0 ? timeoutInterval : 60)] autorelease];
	for (id key in headers)
	{
		if ([key isKindOfClass:[NSString class]] && [[headers objectForKey:key] isKindOfClass:[NSString class]])
			[request setValue:[headers objectForKey:key] forHTTPHeaderField:key];
	}
	if (postData)
	{
		[request setHTTPMethod:@"POST"];
		[request setHTTPBody:postData];
	}
	return request;
}

+ (id)requestWithURL:(NSURL *)url cachePolicy:(NSURLRequestCachePolicy)cachePolicy timeoutInterval:(NSTimeInterval)timeoutInterval customHeaders:(NSDictionary *)headers postString:(NSString *)postString;
{
	return [self requestWithURL:url cachePolicy:cachePolicy timeoutInterval:timeoutInterval customHeaders:headers postData:[postString dataUsingEncoding:NSUTF8StringEncoding]];
}

@end
