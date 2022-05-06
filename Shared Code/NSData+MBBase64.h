//
//  NSData+MBBase64.h
//  MBAtom
//
//  Created by Milo on 10/08/2007.
//  Copyright 2007 Phantom Fish. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSData (MBBase64)

+ (id)dataWithBase64EncodedString:(NSString *)string;     //  Padding '=' characters are optional. Whitespace is ignored.
- (NSString *)base64Encoding;

@end