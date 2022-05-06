//
//  NSMutableArray+MBReordering.m
//  SecuritySpy
//
//  Created by Milo on 10/08/2007.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "NSMutableArray+MBReordering.h"


@implementation NSMutableArray (MBReordering)

- (void)moveObjectAtIndex:(NSUInteger)index toIndex:(NSUInteger)newIndex;
{
	[self insertObject:[self objectAtIndex:index] atIndex:newIndex];
	[self removeObjectAtIndex:(newIndex > index ? index : index + 1)];
}

- (void)moveObjectsFromIndexSet:(NSIndexSet *)indexSet toIndex:(NSUInteger)newIndex;
{
	if (indexSet == nil)
		[NSException raise:NSInvalidArgumentException format:@""];
	
	NSUInteger offset1 = 0, offset2 = 0;
	NSUInteger index = [indexSet firstIndex];
	
	while (index != NSNotFound)
	{
		if (index < newIndex)
		{
			[self insertObject:[self objectAtIndex:index - offset1] atIndex:newIndex];
			[self removeObjectAtIndex:index - offset1];
			offset1++;
		}
		else 
		{
			[self insertObject:[self objectAtIndex:index] atIndex:newIndex + offset2];
			[self removeObjectAtIndex:index + 1];
			offset2++;
		}
		
		index = [indexSet indexGreaterThanIndex:index];
	}
}

@end