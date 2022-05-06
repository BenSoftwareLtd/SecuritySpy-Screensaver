//
//  SSItem+.h
//  SecuritySpy
//
//  Created by Milo on 18/03/2008.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "SSItem.h"
#import "MBURLFetch.h"
@class MBDiskCache;

//  For compatibly with both AppKit and UIKit, we need to define an alias for NSImage/UIImage.
#ifdef SS_iSpy
@compatibility_alias NSUIImage UIImage;
#else
@compatibility_alias NSUIImage NSImage;
#endif


@interface SSItem () <MBURLFetchDelegate>

+ (MBDiskCache *)sharedPreviewCache;
+ (CGFloat)scaleFactor;

- (id)initWithServer:(SSServer *)server;

- (void)clearDiskCache;			//  Clears the preview data from the disk cache. SSServer calls this before the item is permanently deleted to avoid cruft.

//  Concrete subclasses can override the following methods to configure image and preview loading. width and height parameters are added to the URL by SSItem.
- (NSURL *)imageURL;
- (NSURL *)previewURL;
- (BOOL)shouldReloadPreview;	//  NO by default. Concrete subclasses can override this to force the preview to reload even though it may be in the cache.

@property(readwrite, copy, nonatomic) NSString *name;
@property(readwrite, copy, nonatomic) NSNumber *inputNumber;
@property(readwrite, nonatomic) CGSize nativeResolution;
@property(readwrite, retain, nonatomic) id image;
@property(readwrite, retain, nonatomic) id preview;
@property(retain, nonatomic) MBURLFetch *imageFetch;
@property(nonatomic) CGSize imageResolution;
@property(retain, nonatomic) MBURLFetch *previewFetch;
@property(retain, nonatomic) MBDiskCacheTicket *previewCacheTicket;
@end
