//
//  SSServer+.h
//  SecuritySpy
//
//  Created by Milo on 31/07/2007.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "SSServer.h"
#import "MBURLFetch.h"


@interface SSServer () <MBURLFetchDelegate>

+ (NSSet *)keyPathsForValuesAffectingDescription;

- (NSURL *)url;
- (NSDictionary *)requestHeaders;			//  Returns custom HTTP headers to be used for all URL requests.

- (void)postConnectionDidFailNotification:(NSError *)error;

@property(readwrite, copy, nonatomic) NSArray *cameras;
@property(readwrite, copy, nonatomic) NSArray *captures;
@property(retain, nonatomic) MBURLFetch *camerasFetch;
@property(retain, nonatomic) MBURLFetch *capturesFetch;
@end