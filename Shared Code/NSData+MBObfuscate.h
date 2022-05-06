//
//  NSData+MBObfuscate.h
//  SecuritySpy
//
//  Created by Milo on 10/08/2007.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSData (MBObfuscate)		//  Uses random()

//  Set to YES to configure the scrambler to use the host system's byte ordering. This functionality is deprecated but remains for backwards compatibility.
+ (void)setEndianDependentObfuscation:(BOOL)flag;

- (NSData *)dataObfuscatedWithKey:(unsigned long)key;		//  This process is symmetrical, so obfuscate the data twice with the same key to restore it.
@end
