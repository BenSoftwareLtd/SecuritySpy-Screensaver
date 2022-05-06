//
//  MBKeychain.h
//  Byline
//
//  Created by Milo on 09/04/2010.
//  Copyright 2010 Phantom Fish. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface MBKeychain : NSObject
{
}

+ (MBKeychain *)defaultKeychain;

- (NSString *)passwordForUsername:(NSString *)username andServiceName:(NSString *)serviceName;
- (void)setPassword:(NSString *)password forUsername:(NSString *)username andServiceName:(NSString *)serviceName;     //  pass nil for the password to remove the keychain item.

@end
