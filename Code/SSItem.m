//
//  SSItem.m
//  SecuritySpy
//
//  Created by Milo on 18/03/2008.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "SSItem.h"
#import "SSItem+.h"
#import "SSServer.h"
#import "SSServer+.h"
#import "SSTypes.h"
#import "MBDiskCache.h"
#import "DLog.h"

const CGSize SSItemPreviewSize = {100, 75};
NSString *SSItemDidLoadPreviewNotification = @"SSItemDidLoadPreviewNotification";


@implementation SSItem

//  SSItem ()
+ (MBDiskCache *)sharedPreviewCache;
{
	static MBDiskCache *sharedPreviewCache = nil;
	if (sharedPreviewCache == nil)
	{
		sharedPreviewCache = [[MBDiskCache alloc] initWithPath:[NSHomeDirectory() stringByAppendingPathComponent:@"tmp/PreviewCache.db"]];
		[sharedPreviewCache collectGarbage];
	}
	return sharedPreviewCache;
}

//  SSItem ()
+ (CGFloat)scaleFactor;
{
#ifdef SS_iSpy
	return 1.0;		//  TODO: figure out how to get the scale factor in UIKit.
#else
	return [[NSScreen mainScreen] userSpaceScaleFactor];
#endif
}

//  SSItem ()
- (id)initWithServer:(SSServer *)server;
{
	if ([super init] == nil)
		return nil;
	
	NSParameterAssert(server);
	_server = server;
	
	return self;
}

//  NSObject
- (id)init;
{
	return [self initWithServer:nil];
}

//  NSObject
- (void)dealloc;
{
	self.name = nil;
	self.inputNumber = nil;
	self.previewCacheTicket = nil;
	[self stopLoadingImage:YES];
	[self stopLoadingPreview:YES];
	[super dealloc];
}

//  NSObject
- (void)finalize;
{
	[self stopLoadingImage:YES];
	[self stopLoadingPreview:YES];
	[super finalize];
}

//  NSObject
- (NSString *)description;
{
	return (self.name != nil) ? self.name : [super description];
}

//  <NSCoding>
- (id)initWithCoder:(NSCoder *)coder;
{
	if ([super init] == nil)
		return nil;

	_server = [coder decodeObjectForKey:@"SSServer"];
	self.inputNumber = [coder decodeObjectForKey:@"SSInputNumber"];
	self.name = [coder decodeObjectForKey:@"SSName"];
	self.nativeResolution = CGSizeMake([coder decodeDoubleForKey:@"SSNativeSizeWidth"], [coder decodeDoubleForKey:@"SSNativeSizeHeight"]);
	self.previewCacheTicket = [coder decodeObjectForKey:@"SSPreviewCacheTicket"];
	
	return self;
}

//  <NSCoding>
- (void)encodeWithCoder:(NSCoder *)coder;
{
	[coder encodeConditionalObject:self.server forKey:@"SSServer"];
	[coder encodeObject:self.inputNumber forKey:@"SSInputNumber"];
	[coder encodeObject:self.name forKey:@"SSName"];
	[coder encodeDouble:self.nativeResolution.width forKey:@"SSNativeSizeWidth"];
	[coder encodeDouble:self.nativeResolution.height forKey:@"SSNativeSizeHeight"];
	[coder encodeObject:self.previewCacheTicket forKey:@"SSPreviewCacheTicket"];
}

- (void)loadImageWithRequiredDisplaySize:(CGSize)displaySize;
{
	if ([self.server url] == nil)
	{
		[self.server postConnectionDidFailNotification:nil];
		return;
	}

	displaySize.width = MIN(self.nativeResolution.width, displaySize.width * [[self class] scaleFactor]);
	displaySize.height = MIN(self.nativeResolution.height, displaySize.height * [[self class] scaleFactor]);
	if (displaySize.width == 0 || displaySize.height == 0)
		displaySize = self.nativeResolution;
	
	//  Increase one dimension if necessary to preserve aspect ratio.
	CGFloat aspectRatio = self.nativeResolution.width / self.nativeResolution.height;
	if ((displaySize.width / displaySize.height) > aspectRatio)
		displaySize.height = floor(displaySize.width / aspectRatio);
	else displaySize.width = floor(displaySize.height * aspectRatio);
	
	//  If a connection is already open and offering sufficient resolution, don't mess with it.
	if (self.imageFetch != nil && displaySize.width <= self.imageResolution.width && displaySize.height <= self.imageResolution.height)
		return;
	
	[self stopLoadingImage:NO];
	
	NSURL *requestURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@&width=%.0f&height=%.0f", [[self imageURL] relativeString], displaySize.width, displaySize.height] relativeToURL:[self imageURL]];
	
	DLog(@"Opening image connection to item '%@'. Resolution is %.0fx%.0f.", self, displaySize.width, displaySize.height);
	self.imageResolution = displaySize;
	self.imageFetch = [MBURLFetch fetchWithURLRequest:[NSMutableURLRequest requestWithURL:requestURL cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:0 customHeaders:[self.server requestHeaders] postString:nil]];
	self.imageFetch.delegate = self;
	[self.imageFetch start];
}

- (void)stopLoadingImage:(BOOL)releaseMemory;
{
	[self.imageFetch cancel];
	self.imageFetch = nil;
	self.imageResolution = CGSizeMake(0,0);
	
	if (releaseMemory)
		self.image = nil;
}

- (void)loadPreview;
{
	if (self.preview == nil && self.previewCacheTicket != nil)
	{
		NSData *data = [[[self class] sharedPreviewCache] dataForTicket:self.previewCacheTicket];
		if (data == nil)
			self.previewCacheTicket = nil;
		else
		{
			id image = [[NSUIImage alloc] initWithData:data];
			self.preview = image;
			[image release];
		}
	}
	
	if ([self.server url] == nil)
	{
		[self.server postConnectionDidFailNotification:nil];
		return;
	}
	
	if (self.preview != nil && [self shouldReloadPreview] == NO)
		return;
		
	NSURL *requestURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@&width=%.0f&height=%.0f", [[self previewURL] relativeString], SSItemPreviewSize.width * [[self class] scaleFactor], SSItemPreviewSize.height * [[self class] scaleFactor]] relativeToURL:[self previewURL]];
	
	if ([[[self.previewFetch.request URL] absoluteString] isEqualToString:[requestURL absoluteString]])		//  An identical request is already queued.
	{
		self.previewFetch.queuePriority = MBURLFetchQueuePriorityLow;
		return;
	}
	
	[self stopLoadingPreview:NO];
	
	self.previewFetch = [MBURLFetch fetchWithURLRequest:[NSMutableURLRequest requestWithURL:requestURL cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:0 customHeaders:[self.server requestHeaders] postString:nil]];
	self.previewFetch.delegate = self;
	self.previewFetch.queuePriority = MBURLFetchQueuePriorityLow;
	[[MBURLFetchQueue sharedFetchQueue] addFetch:self.previewFetch];
}

- (void)reducePreviewLoadingPriority;
{
	self.previewFetch.queuePriority = MBURLFetchQueuePriorityVeryLow;
}

- (void)stopLoadingPreview:(BOOL)releaseMemory;
{
	[self.previewFetch cancel];
	self.previewFetch = nil;
	
	if (releaseMemory)
		self.preview = nil;
}

//  SSItem ()
- (void)clearDiskCache;
{
	//  First stop any open or queued connection to download preview data.
	[self stopLoadingPreview:NO];

	if (self.previewCacheTicket != nil)
		[[[self class] sharedPreviewCache] removeDataForTicket:self.previewCacheTicket];
		
	self.previewCacheTicket = nil;
}

//  SSItem ()
- (NSURL *)imageURL;
{
	return [NSURL URLWithString:@""];
}

//  SSItem ()
- (NSURL *)previewURL;
{
	return [NSURL URLWithString:@""];
}

//  SSItem ()
- (BOOL)shouldReloadPreview;
{
	return NO;
}

//  <MBURLFetchDelegate>
- (void)fetch:(MBURLFetch *)fetch didReceiveResponse:(NSURLResponse *)response withData:(NSMutableData *)data;
{
	if (fetch == self.previewFetch)
	{
		if (fetch.finished == NO)
			return;
		[self stopLoadingPreview:NO];
		
		if ([data length] == 0 || [[response MIMEType] isEqualToString:@"image/jpeg"] == NO)
		{
			[self.server postConnectionDidFailNotification:nil];
			return;
		}
	
		if (self.previewCacheTicket == nil)
			self.previewCacheTicket = [[[self class] sharedPreviewCache] addData:data];
		else [[[self class] sharedPreviewCache] setData:data forTicket:self.previewCacheTicket];
		
		id preview = [[NSUIImage alloc] initWithData:data];
		self.preview = preview;
		[preview release];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:SSItemDidLoadPreviewNotification object:self userInfo:nil];
	}
	else if (fetch == self.imageFetch)
	{
		if (fetch.finished)
			[self stopLoadingImage:NO];
			
		if ([[response MIMEType] isEqualToString:@"multipart/x-mixed-replace"])
			return;
		else if ([data length] == 0 || [[response MIMEType] isEqualToString:@"image/jpeg"] == NO)
		{
			[self stopLoadingImage:NO];
			[self.server postConnectionDidFailNotification:nil];
			return;
		}
	
		id image = [[NSUIImage alloc] initWithData:data];
		self.image = image;
		[image release];
	}
}

//  <MBURLFetchDelegate>
- (NSCachedURLResponse *)fetch:(MBURLFetch *)fetch willCacheResponse:(NSCachedURLResponse *)cachedResponse;
{
	return nil;
}

//  <MBURLFetchDelegate>
- (void)fetch:(MBURLFetch *)fetch didFailWithError:(NSError *)error;
{
	if (fetch == self.imageFetch)
		[self stopLoadingImage:NO];
	else if (fetch == self.previewFetch)
		[self stopLoadingPreview:NO];
	[self.server postConnectionDidFailNotification:error];
}

@synthesize server = _server;
@synthesize name = _name;
@synthesize inputNumber = _inputNumber;
@synthesize nativeResolution = _nativeResolution;
@synthesize image = _image;
@synthesize preview = _preview;
@synthesize imageFetch = _imageFetch;
@synthesize imageResolution = _imageResolution;
@synthesize previewFetch = _previewFetch;
@synthesize previewCacheTicket = _previewCacheTicket;

@end
