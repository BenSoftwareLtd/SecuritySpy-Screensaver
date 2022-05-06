//
//  NSURLRequest+IgnoreSSL.m
//  SecuritySpyScreenSaver
//
//  Created by benbird on 17/11/2014.
//  Copyright (c) 2014 benbird. All rights reserved.
//

#import "NSURLRequest+IgnoreSSL.h"
 
@implementation NSURLRequest (IgnoreSSL)
+ (BOOL)allowsAnyHTTPSCertificateForHost:(NSString*)host
{
	return YES;
}
 
@end
