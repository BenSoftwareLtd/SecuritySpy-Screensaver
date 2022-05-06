//
//  SSItem.h
//  SecuritySpy
//
//  Abstract superclass to represent either a camera or an item of captured footage.
//
//  Created by Milo on 18/03/2008.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
@class SSServer;
@class MBURLFetch;
@class MBDiskCacheTicket;

extern const CGSize SSItemPreviewSize;		//  In points.


@interface SSItem : NSObject <NSCoding>
{
	SSServer			*_server;
	NSString			*_name;
	NSNumber			*_inputNumber;
	CGSize				_nativeResolution;
	id					_image;
	id					_preview;
	MBURLFetch			*_imageFetch;
	CGSize				_imageResolution;
	MBURLFetch			*_previewFetch;
	MBDiskCacheTicket	*_previewCacheTicket;
}

//  When loading the image, pass the expected display size - in points - in order to save on bandwidth. Set to (0, 0) for the default behaviour, which is the native resolution. The actual resolution of the image requested might be slightly larger in one dimension or the other in order to preserve the correct aspect ratio. If the connection is already open but has a smaller display size, a fresh connection will be started.
- (void)loadImageWithRequiredDisplaySize:(CGSize)displaySize;
- (void)stopLoadingImage:(BOOL)releaseMemory;
- (void)loadPreview;					//  Loads the preview into memory. If in the cache it is loaded immediately, otherwise it is queued for asynchronous download from the server.
- (void)reducePreviewLoadingPriority;	//  Reduces the priority of the pending preview download, if there is one. Calling -loadPreview afterwards restores the standard priority.
- (void)stopLoadingPreview:(BOOL)releaseMemory;

@property(readonly, nonatomic) SSServer *server;
@property(readonly, copy, nonatomic) NSString *name;
@property(readonly, copy, nonatomic) NSNumber *inputNumber;
@property(readonly, nonatomic) CGSize nativeResolution;		//  In pixels.
@property(readonly, retain, nonatomic) id image;			//  An instance of NSImage or UIImage, depending on the available framework.
@property(readonly, retain, nonatomic) id preview;
@end


@protocol SSItemNotifications

@optional
- (void)itemDidLoadPreview:(NSNotification *)notification;		//  Posted when the preview is loaded from the server, not from the cache.
@end

extern NSString *SSItemDidLoadPreviewNotification;