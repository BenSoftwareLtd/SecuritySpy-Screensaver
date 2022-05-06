//
//  MBASCIIOnlyStringFormatter.m
//  SecuritySpy
//
//  Created by Milo on 22/04/2008.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MBASCIIOnlyStringFormatter.h"


@implementation MBASCIIOnlyStringFormatter

//  NSFormatter
- (NSString *)stringForObjectValue:(id)object;
{
	if ([object isKindOfClass:[NSString class]])
		return object;
	else return nil;
}

//  NSFormatter
- (BOOL)getObjectValue:(id *)object forString:(NSString *)string errorDescription:(NSString **)error;
{
	*object = string;
	return YES;
}

//  NSFormatter
- (BOOL)isPartialStringValid:(NSString **)partialStringPtr proposedSelectedRange:(NSRangePointer)proposedSelRangePtr originalString:(NSString *)origString originalSelectedRange:(NSRange)origSelRange errorDescription:(NSString **)error;
{
	if (proposedSelRangePtr->location <= origSelRange.location)		//  Always allow deletions.
		return YES;

	if ([*partialStringPtr canBeConvertedToEncoding:NSASCIIStringEncoding])
		return YES;
		
	NSBeep();
	if (error != NULL)
		*error = @"Non-ASCII characters are not supported.";
	return NO;
}

@end
