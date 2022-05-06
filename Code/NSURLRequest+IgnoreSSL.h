//
//  NSURLRequest+IgnoreSSL.h
//  SecuritySpyScreenSaver
//
//  Created by benbird on 17/11/2014.
//  Copyright (c) 2014 benbird. All rights reserved.
//

@interface NSURLRequest (IgnoreSSL)
 
+ (BOOL)allowsAnyHTTPSCertificateForHost:(NSString*)host;
 
@end
