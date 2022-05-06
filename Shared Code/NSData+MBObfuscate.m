//
//  NSData+MBObfuscate.m
//  SecuritySpy
//
//  Created by Milo on 10/08/2007.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "NSData+MBObfuscate.h"


@implementation NSData (MBObfuscate)

static BOOL endianDependentObfuscation = NO;

static inline long MBRandom()
{
	if (!endianDependentObfuscation)
		return NSSwapHostLongToLittle(random());
	else return random();
}

+ (void)setEndianDependentObfuscation:(BOOL)flag;
{
	endianDependentObfuscation = flag;
}

- (NSData *)dataObfuscatedWithKey:(unsigned long)key;
{
	if ([self length] == 0)
		return [NSData data];

	srandom((unsigned)key);
	
	UInt8 *bytes = malloc([self length]);
	if (bytes == NULL)
		return nil;
	[self getBytes:bytes];
	
	UInt32 scrambler;
	NSUInteger i = 0;
	
	//  Scramble in chunks.
	if ([self length] > sizeof(scrambler))
	{
		for (i = 0; i <= [self length] - sizeof(scrambler); i += sizeof(scrambler))
		{
			scrambler = (UInt32)MBRandom();
			*(UInt32 *)(bytes + i) ^= scrambler;
		}		
	}
	
	//  Scramble any remaining bytes one at a time.
	scrambler = (UInt32)MBRandom();
	UInt8 *byteScrambler = (UInt8 *)&scrambler;
	while(i < [self length])
		bytes[i++] ^= *(byteScrambler++);
	
	return [NSData dataWithBytesNoCopy:bytes length:[self length]];
}

@end
