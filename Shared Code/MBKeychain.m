//
//  MBKeychain.m
//  Byline
//
//  Created by Milo on 09/04/2010.
//  Copyright 2010 Phantom Fish. All rights reserved.
//

#import <Security/Security.h>
#import "MBKeychain.h"

static MBKeychain *defaultKeychain = nil;


@implementation MBKeychain

+ (void)initialize;
{
	if (self != [MBKeychain class])
		return;
	defaultKeychain = [[self alloc] init];
}

+ (MBKeychain *)defaultKeychain;
{
	return defaultKeychain;
}

- (NSString *)passwordForUsername:(NSString *)username andServiceName:(NSString *)serviceName;
{
	if (!username || !serviceName)
		[NSException raise:NSInvalidArgumentException format:@""];
	NSData *data = nil;
	SecItemCopyMatching((CFDictionaryRef)[NSDictionary dictionaryWithObjectsAndKeys:(NSString *)kSecClassGenericPassword, (NSString *)kSecClass, username, kSecAttrAccount, serviceName, kSecAttrService, (id)kCFBooleanTrue, (id)kSecReturnData, nil], (CFTypeRef *)&data);
	NSString *password = (data ? [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease] : nil);
	[data release];
	return password;
}

- (void)setPassword:(NSString *)password forUsername:(NSString *)username andServiceName:(NSString *)serviceName;
{
	if (!username || !serviceName)
		[NSException raise:NSInvalidArgumentException format:@""];
	if (!password)
		SecItemDelete((CFDictionaryRef)[NSDictionary dictionaryWithObjectsAndKeys:(NSString *)kSecClassGenericPassword, (NSString *)kSecClass, username, kSecAttrAccount, serviceName, kSecAttrService, nil]);
	else if ([self passwordForUsername:username andServiceName:serviceName])
		SecItemUpdate((CFDictionaryRef)[NSDictionary dictionaryWithObjectsAndKeys:(NSString *)kSecClassGenericPassword, (NSString *)kSecClass, username, kSecAttrAccount, serviceName, kSecAttrService, serviceName, kSecAttrLabel, nil], (CFDictionaryRef)[NSDictionary dictionaryWithObject:[password dataUsingEncoding:NSUTF8StringEncoding] forKey:(NSString *) kSecValueData]);
	else SecItemAdd((CFDictionaryRef)[NSDictionary dictionaryWithObjectsAndKeys:(NSString *)kSecClassGenericPassword, (NSString *)kSecClass, username, kSecAttrAccount, serviceName, kSecAttrService, serviceName, kSecAttrLabel, [password dataUsingEncoding:NSUTF8StringEncoding], kSecValueData, nil], NULL);
}

@end
