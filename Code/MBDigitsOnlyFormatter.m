//
//  MBDigitsOnlyFormatter.m
//  SecuritySpy
//
//  Created by Milo on 08/08/2007.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "MBDigitsOnlyFormatter.h"


@implementation MBDigitsOnlyFormatter

- (BOOL)isPartialStringValid:(NSString *)partialString newEditingString:(NSString **)newString errorDescription:(NSString **)error;
{
	NSDecimalNumber *check;
	if ([self getObjectValue:&check forString:partialString errorDescription:error])
		return YES;

	NSBeep();
	return NO;
}

@end
