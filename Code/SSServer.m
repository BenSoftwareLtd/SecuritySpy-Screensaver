//
//  SSServer.m
//  SecuritySpy
//
//  Created by Milo on 31/07/2007.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "SSServer.h"
#import "SSServer+.h"
#import "SSItem.h"
#import "SSItem+.h"
#import "SSCamera.h"
#import "SSCapture.h"
#import "SSTypes.h"
#import "NSData+MBObfuscate.h"
#import "NSData+MBBase64.h"
#import "DLog.h"

NSString *SSServerDidLoadCamerasNotification = @"SSServerDidLoadCamerasNotification";
NSString *SSServerDidLoadCapturesNotification = @"SSServerDidLoadCapturesNotification";
NSString *SSServerInsertedItemsNotificationKey = @"SSServerNotificationInsertedItemsKey";
NSString *SSServerRemovedItemsNotificationKey = @"SSServerNotificationRemovedItemsKey";
NSString *SSServerUpdatedItemsNotificationKey = @"SSServerNotificationUpdatedItemsKey";
NSString *SSServerConnectionDidFailNotification = @"SSServerConnectionDidFailNotification";
NSString *SSServerErrorNotificationKey = @"SSServerNotificationErrorKey";


@implementation SSServer

+ (NSSet *)keyPathsForValuesAffectingDescription;
{
	return [NSSet setWithObjects:@"name", @"address", nil];
}

//  NSObject
- (id)init;
{
	if ([super init] == nil)
		return nil;
	
	self.frameRate = [NSNumber numberWithUnsignedInt:5];
	self.cameras = [NSArray array];
	self.captures = [NSArray array];
	
	[self addObserver:self forKeyPath:@"address" options:0 context:NULL];
	[self addObserver:self forKeyPath:@"username" options:0 context:NULL];
	[self addObserver:self forKeyPath:@"password" options:0 context:NULL];
	[self addObserver:self forKeyPath:@"sslFlag" options:0 context:NULL];
	
	return self;
}

//  NSObject
- (void)dealloc;
{
	[self removeObserver:self forKeyPath:@"address"];
	[self removeObserver:self forKeyPath:@"username"];
	[self removeObserver:self forKeyPath:@"password"];
	[self removeObserver:self forKeyPath:@"sslFlag"];

	self.name = nil;
	self.address = nil;
	self.username = nil;
	self.password = nil;
	self.frameRate = nil;
	self.sslFlag = nil;
	self.cameras = nil;
	self.captures = nil;
	[self.camerasFetch cancel];
	self.camerasFetch = nil;
	[self.capturesFetch cancel];
	self.capturesFetch = nil;
	[_url release];
	[_requestHeaders release];
	
	[super dealloc];
}

//  NSObject
- (void)finalize;
{
	[self.camerasFetch cancel];
	[self.capturesFetch cancel];
	[super finalize];
}

//  NSObject
- (NSString *)description;
{
	if ([self.name length] != 0)
		return self.name;
	else if ([self.address length] != 0)
		return self.address;
	else return @"New Server";
}

//  <NSCoding>
- (id)initWithCoder:(NSCoder *)coder;
{
	if ([super init] == nil)
		return nil;

//NSLog(@"self.sslFlag 1: %d",(int)[self.sslFlag boolValue]);

	self.name = [coder decodeObjectForKey:@"SSName"];
	self.address = [coder decodeObjectForKey:@"SSAddress"];
	self.username = [coder decodeObjectForKey:@"SSUsername"];
	self.password = [[[NSString alloc] initWithData:[[coder decodeObjectForKey:@"SSPasswordData"] dataObfuscatedWithKey:82031280] encoding:NSUnicodeStringEncoding] autorelease];
	self.frameRate = [coder decodeObjectForKey:@"SSFrameRate"];
	self.sslFlag = [coder decodeObjectForKey:@"SSSSLFlag"];
	self.cameras = [coder decodeObjectForKey:@"SSCameras"];
	self.captures = [coder decodeObjectForKey:@"SSCaptures"];

//NSLog(@"self.sslFlag 2: %d",(int)[self.sslFlag boolValue]);

	DLog(@"%@: %@", self.address, self.password);
	
	[self addObserver:self forKeyPath:@"address" options:0 context:NULL];
	[self addObserver:self forKeyPath:@"username" options:0 context:NULL];
	[self addObserver:self forKeyPath:@"password" options:0 context:NULL];
	[self addObserver:self forKeyPath:@"sslFlag" options:0 context:NULL];
	
	return self;
}

//  <NSCoding>
- (void)encodeWithCoder:(NSCoder *)coder;
{
	[coder encodeObject:self.name forKey:@"SSName"];
	[coder encodeObject:self.address forKey:@"SSAddress"];
	[coder encodeObject:self.username forKey:@"SSUsername"];
	[coder encodeObject:[[self.password dataUsingEncoding:NSUnicodeStringEncoding] dataObfuscatedWithKey:82031280] forKey:@"SSPasswordData"];
	[coder encodeObject:self.frameRate forKey:@"SSFrameRate"];
	[coder encodeObject:self.sslFlag forKey:@"SSSSLFlag"];
	[coder encodeObject:self.cameras forKey:@"SSCameras"];
	[coder encodeObject:self.captures forKey:@"SSCaptures"];
}

- (void)loadCameras;
{
	if ([self url] == nil)
	{
		[self postConnectionDidFailNotification:nil];
		return;
	}
	NSURL *requestURL = [NSURL URLWithString:@"++inputListData" relativeToURL:[self url]];

//NSLog(@"URL: %@",requestURL);//xxx

	if ([[[self.camerasFetch.request URL] absoluteString] isEqualToString:[requestURL absoluteString]])		//  An identical request is already queued.
		return;
	
	[self.camerasFetch cancel];
	self.camerasFetch = [MBURLFetch fetchWithURLRequest:[NSMutableURLRequest requestWithURL:requestURL cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:0 customHeaders:[self requestHeaders] postString:nil]];
	self.camerasFetch.delegate = self;
	[[MBURLFetchQueue sharedFetchQueue] addFetch:self.camerasFetch];
}

- (void)loadCaptures;
{
	//  TODO: temporary.
	SSCapture *capture = [[SSCapture alloc] initWithServer:self];
	capture.name = @"Test Capture";
	capture.captureURL = [NSURL URLWithString:@"http://www.milobird.com/testcapture.mov"];
	self.captures = [NSArray arrayWithObject:capture];
	[capture release];
}

- (void)loadExtraCaptures:(NSUInteger)number;
{
}

- (void)releaseExtraCaptures;
{
}

- (void)clearDiskCache;
{
	[self.cameras makeObjectsPerformSelector:@selector(clearDiskCache)];
	[self.captures makeObjectsPerformSelector:@selector(clearDiskCache)];
}

//  SSServer ()
- (NSURL *)url;
{
	if ([self.address length] == 0)
		return nil;
		
	if (_url == nil)
	{
		NSMutableArray *stringComponents = [[self.address componentsSeparatedByString:@"/"] mutableCopy];
		
		//  Add the default scheme if necessary.
		if ([stringComponents count] < 3 || [[stringComponents objectAtIndex:1] length] != 0)
		{
			if ([self.sslFlag boolValue]) [stringComponents insertObject:@"https:" atIndex:0];
   else [stringComponents insertObject:@"http:" atIndex:0];
   
			[stringComponents insertObject:@"" atIndex:1];
		}
		
		//  Add the default port if necessary.
		if ([[stringComponents objectAtIndex:2] rangeOfString:@":"].location == NSNotFound)
  {
			if ([self.sslFlag boolValue]) [stringComponents replaceObjectAtIndex:2 withObject:[[stringComponents objectAtIndex:2] stringByAppendingString:@":8001"]];
   else [stringComponents replaceObjectAtIndex:2 withObject:[[stringComponents objectAtIndex:2] stringByAppendingString:@":8000"]];
		}
  
		//  Add username and password if necessary.
		if ([self.username length] > 0)
			[stringComponents replaceObjectAtIndex:2 withObject:[NSString stringWithFormat:@"%@:%@@%@", self.username, ([self.password length] > 0) ? self.password : @"", [stringComponents objectAtIndex:2]]];
		
		//  Add a final forward slash if necessary.
		if ([[stringComponents lastObject] length] != 0)
			[stringComponents addObject:@""];
		
		_url = [[NSURL alloc] initWithString:[stringComponents componentsJoinedByString:@"/"]];
		[stringComponents release];
	}
	
	return _url;
}

//  SSServer ()
- (NSDictionary *)requestHeaders;
{
	if (_requestHeaders == nil)
	{
		_requestHeaders = [[NSMutableDictionary alloc] init];
		
#ifdef SS_iSpy
		//  Set the User Agent to <bundleID>/<bundleVersion>. iSpy only, as a User Agent string containing "SecuritySpy" causes problems with older verisons of SecuritySpy.
		[_requestHeaders setObject:[NSString stringWithFormat:@"%@/%@", [[NSBundle bundleForClass:[SSServer class]] bundleIdentifier], [[NSBundle bundleForClass:[SSServer class]] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey]] forKey:@"User-Agent"];
#endif
		
		//  Set fake headers to indicate to SecuritySpy that the demo message should be left off when the User-Agent string contains "com.PhantomFish".
		[_requestHeaders setObject:@"53" forKey:@"User-Class"];
		[_requestHeaders setObject:@"off" forKey:@"Connection-Timeout"];
		
		// Set header for HTTP Basic authentication explicitly, to avoid NSURLCredentialStorage intervention.
		if ([self.username length] > 0)
			[_requestHeaders setObject:[NSString stringWithFormat:@"Basic %@", [[[NSString stringWithFormat:@"%@:%@", self.username, ([self.password length] > 0) ? self.password : @""] dataUsingEncoding:NSUTF8StringEncoding] base64Encoding]] forKey:@"Authorization"];
	}
	
	return _requestHeaders;
}

//  SSServer ()
- (void)postConnectionDidFailNotification:(NSError *)error;
{
	DLog(@"Fetch failed for server '%@'! Error - %@ %@ %d", self, [error localizedDescription], [[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey], [error code]);

	NSDictionary *userInfo = (error == nil) ? nil : [[NSDictionary alloc] initWithObjectsAndKeys:error, SSServerErrorNotificationKey, nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:SSServerConnectionDidFailNotification object:self userInfo:userInfo];
	[userInfo release];
}

//  <MBURLFetchDelegate>
- (void)fetch:(MBURLFetch *)fetch didReceiveResponse:(NSURLResponse *)response withData:(NSMutableData *)data;
{
	if (fetch.finished == NO)
		return;

	if (fetch == self.camerasFetch)
	{
		self.camerasFetch = nil;
	
		if ([[response MIMEType] isEqualToString:@"camdata/ss"] == NO)
		{
			[self postConnectionDidFailNotification:nil];
			return;
		}
		
		if ([data length] == 0)
			return;
		
		NSMutableArray *newCameras = [self.cameras mutableCopy];
		NSMutableArray *insertedCameras = [[NSMutableArray alloc] initWithCapacity:5];
		NSMutableArray *removedCameras = [[NSMutableArray alloc] initWithCapacity:5];
		NSMutableArray *updatedCameras = [[NSMutableArray alloc] initWithCapacity:5];
		
		NSUInteger i;
		for (i = 0; i < [data length] / sizeof(InputListStruct); i++)
		{
			InputListStruct input;
			[data getBytes:&input range:NSMakeRange(i * sizeof(InputListStruct), sizeof(InputListStruct))];
			
			//  Swap bytes if necessary.
			input.inputNum = NSSwapBigShortToHost(input.inputNum);
			input.videoWidth = NSSwapBigShortToHost(input.videoWidth);
			input.videoHeight = NSSwapBigShortToHost(input.videoHeight);
			
			//  Delete any old cameras that no longer exist.
			while (i < [newCameras count] && [[[newCameras objectAtIndex:i] inputNumber] shortValue] < input.inputNum)
			{
				[removedCameras addObject:[newCameras objectAtIndex:i]];
				[[newCameras objectAtIndex:i] clearDiskCache];
				[newCameras removeObjectAtIndex:i];
			}
			
			//  If this camera is new, create an object to represent it.
			if (i >= [newCameras count] || [[[newCameras objectAtIndex:i] inputNumber] shortValue] > input.inputNum)
			{
				SSCamera *camera = [[SSCamera alloc] initWithServer:self];
				[newCameras insertObject:camera atIndex:i];
				[insertedCameras addObject:camera];
				[camera release];
			}
			
			//  Update the camera's properties.
			SSCamera *camera = [newCameras objectAtIndex:i];
			NSString *name = NSMakeCollectable(CFStringCreateWithPascalString(kCFAllocatorDefault, input.inputName, kCFStringEncodingUTF8));
			if (camera.name != nil && [camera.name isEqualToString:name] == NO)
				[updatedCameras addObject:camera];
			camera.name = name;
			[name release];
			if (camera.inputNumber == nil)
				camera.inputNumber = [NSNumber numberWithShort:input.inputNum];
			else NSParameterAssert([camera.inputNumber shortValue] == input.inputNum);
			camera.nativeResolution = CGSizeMake(input.videoWidth, input.videoHeight);
		}
		
		//  Remove any remaining old cameras from the end of the list.
		while (i < [newCameras count])
		{
			[removedCameras addObject:[newCameras objectAtIndex:i]];
			[[newCameras objectAtIndex:i] clearDiskCache];
			[newCameras removeObjectAtIndex:i];
		}
		
		if ([insertedCameras count] != 0 || [removedCameras count] != 0 || [updatedCameras count] != 0)
		{
			self.cameras = newCameras;
			NSDictionary *userInfo = [[NSDictionary alloc] initWithObjectsAndKeys:insertedCameras, SSServerInsertedItemsNotificationKey, removedCameras, SSServerRemovedItemsNotificationKey, updatedCameras, SSServerUpdatedItemsNotificationKey, nil];
			[[NSNotificationCenter defaultCenter] postNotificationName:SSServerDidLoadCamerasNotification object:self userInfo:userInfo];
			[userInfo release];
		}
		
		[newCameras release];
		[insertedCameras release];
		[removedCameras release];
		[updatedCameras release];
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
	if (fetch == self.camerasFetch)
		self.camerasFetch = nil;
	if (fetch == self.capturesFetch)
		self.capturesFetch = nil;
	[self postConnectionDidFailNotification:error];
}

//  NSObject (NSKeyValueObserving)
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context;
{	
	[_url release];
	_url = nil;

//NSLog(@"observeValueForKeyPath");

	/*if ([keyPath isEqualToString:@"username"] || [keyPath isEqualToString:@"password"])
	{
		[_requestHeaders release];
		_requestHeaders = nil;
	}*/

	//else if ([keyPath isEqualToString:@"address"] || [keyPath isEqualToString:@"sslFlag"])
	//{
		//  Reset the list of cameras and captures, as we may now be representing a different server.
  
  [_requestHeaders release];
		_requestHeaders = nil;
  
		[self clearDiskCache];
		self.cameras = [NSArray array];
		self.captures = [NSArray array];
		[self.camerasFetch cancel];
		self.camerasFetch = nil;
		[self.capturesFetch cancel];
		self.capturesFetch = nil;
	//}
}

@synthesize name = _name;
@synthesize address = _address;
@synthesize username = _username;
@synthesize password = _password;
@synthesize frameRate = _frameRate;
@synthesize sslFlag = _sslFlag;
@synthesize cameras = _cameras;
@synthesize captures = _captures;
@synthesize camerasFetch = _camerasFetch;
@synthesize capturesFetch = _capturesFetch;

@end