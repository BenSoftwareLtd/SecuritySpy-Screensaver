//
//  SSServer.h
//  SecuritySpy
//
//  Represents a SecuritySpy server.
//
//  Created by Milo on 31/07/2007.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
@class MBURLFetch;

@interface NSURLRequest (DummyInterface)
+ (BOOL)allowsAnyHTTPSCertificateForHost:(NSString*)host;
+ (void)setAllowsAnyHTTPSCertificate:(BOOL)allow forHost:(NSString*)host;
@end

@interface SSServer : NSObject <NSCoding>
{
	NSString            *_name;
	NSString            *_address;
	NSString            *_username;
	NSString            *_password;
	NSNumber            *_frameRate;
 NSNumber            *_sslFlag;
	NSArray             *_cameras;
	NSArray             *_captures;
	MBURLFetch          *_camerasFetch;
	MBURLFetch          *_capturesFetch;
	NSURL               *_url;
	NSMutableDictionary *_requestHeaders;
}

//  The following server requests are queued and loaded asynchronously.
- (void)loadCameras;			//  Refreshes the camera list.
- (void)loadCaptures;			//  Refreshes the captures list, trimming it to the 25 newest.
- (void)loadExtraCaptures:(NSUInteger)number;		//  Loads the specified number of extra captures.
- (void)releaseExtraCaptures;	//  Trims the captures list to the newest 25. Cancels any pending requests to load captures.
- (void)clearDiskCache;			//  Removes preview data from the disk cache. Call this before permanently deleting the server to avoid cruft.

@property(copy, nonatomic) NSString *name;
@property(copy, nonatomic) NSString *address;		//  Changing the address will reset the cameras and captures arrays and cancels pending server requests.
@property(copy, nonatomic) NSString *username;
@property(copy, nonatomic) NSString *password;
@property(copy, nonatomic) NSNumber *sslFlag;
@property(copy, nonatomic) NSNumber *frameRate;
//  Camera and capture objects don't retain their server objects, so these objects should not be kept beyond the life of the server object.
@property(readonly, copy, nonatomic) NSArray *cameras;
@property(readonly, copy, nonatomic) NSArray *captures;
@end


@protocol SSServerNotifications

@optional
- (void)serverDidLoadCameras:(NSNotification *)notification;		//  Posted when cameras are added, removed, or updated.
- (void)serverDidLoadCaptures:(NSNotification *)notification;		//  Posted when captures are added and/or removed.
- (void)serverConnectionDidFail:(NSNotification *)notification;		//  Posted when a server or one of its items gets an error from NSURLConnection, or when the response received is unexpected, or when the connection could not started in the first place.
@end

extern NSString *SSServerDidLoadCamerasNotification;
extern NSString *SSServerDidLoadCapturesNotification;
extern NSString *SSServerInsertedItemsNotificationKey;		//  NSArray
extern NSString *SSServerRemovedItemsNotificationKey;		//  NSArray
extern NSString *SSServerUpdatedItemsNotificationKey;		//  NSArray

extern NSString *SSServerConnectionDidFailNotification;
extern NSString *SSServerErrorNotificationKey;				//  NSError - NSURLErrorDomain