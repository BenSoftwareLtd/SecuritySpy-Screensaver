//
//  MBDiskCache.m
//  SecuritySpy
//
//  Created by Milo on 18/03/2008.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MBDiskCache.h"
#import "MBDiskCacheTicket+.h"
#import "DLog.h"


@interface MBDiskCache ()

- (BOOL)removeDataForCacheID:(NSNumber *)cacheID;
@end


@implementation MBDiskCache

- (id)initWithPath:(NSString *)path;
{
	if ([super init] == nil)
		return nil;
	if (path == nil)
		[NSException raise:NSInvalidArgumentException format:@""];
	
	if (sqlite3_open([path UTF8String], &_database) == SQLITE_OK)
	{
		sqlite3_stmt *statement;
		if (sqlite3_prepare_v2(_database, "CREATE TABLE IF NOT EXISTS mbdiskcache (id INTEGER PRIMARY KEY, data BLOB)", -1, &statement, NULL) == SQLITE_OK)
		{
			int result = sqlite3_step(statement);
			sqlite3_finalize(statement);
			if (result == SQLITE_DONE && sqlite3_prepare_v2(_database, "PRAGMA cache_size = 0", -1, &statement, NULL) == SQLITE_OK)      //  disable memory caching - that's the application's responsibility.
			{
				result = sqlite3_step(statement);
				sqlite3_finalize(statement);
			}
			if (result == SQLITE_DONE)
				return self;
		}
	}
	
	DLog(@"MBDiskCache could not open database with path \"%@\"!", path);
	sqlite3_close(_database);
	[self release];
	return nil;
}

//  NSObject
- (id)init;
{
	return [self initWithPath:nil];
}

//  NSObject
- (void)dealloc;
{
	if (_addStatement != NULL) sqlite3_finalize(_addStatement);
	if (_queryStatement != NULL) sqlite3_finalize(_queryStatement);
	if (_setStatement != NULL) sqlite3_finalize(_setStatement);
	if (_deleteStatement != NULL) sqlite3_finalize(_deleteStatement);
	if (_listStatement != NULL) sqlite3_finalize(_listStatement);
	if (_beginTransactionStatement != NULL) sqlite3_finalize(_beginTransactionStatement);
	if (_commitTransactionStatement != NULL) sqlite3_finalize(_commitTransactionStatement);
	sqlite3_close(_database);
	[super dealloc];
}

- (MBDiskCacheTicket *)addData:(NSData *)data;
{
	if (data == nil)
		[NSException raise:NSInvalidArgumentException format:@""];
		
	if (_addStatement == NULL)
		sqlite3_prepare_v2(_database, "INSERT INTO mbdiskcache (data) values (?)", -1, &_addStatement, NULL);
		
	MBDiskCacheTicket *ticket = nil;
	if (_addStatement != NULL)
	{
		sqlite3_bind_blob(_addStatement, 1, [data bytes], (int)[data length], SQLITE_STATIC);
		if (sqlite3_step(_addStatement) == SQLITE_DONE)
			ticket = [[[MBDiskCacheTicket alloc] initWithCacheID:[NSNumber numberWithLongLong:sqlite3_last_insert_rowid(_database)] datestamp:[NSDate date]] autorelease];
		sqlite3_reset(_addStatement);
		sqlite3_clear_bindings(_addStatement);
	}
	
	if (ticket == nil)
		DLog(@"MBDiskCache could not add data to database!");
	return ticket;
}

- (NSData *)dataForTicket:(MBDiskCacheTicket *)ticket;
{
	if (ticket == nil)
		[NSException raise:NSInvalidArgumentException format:@""];
	
	if (_queryStatement == NULL)
		sqlite3_prepare_v2(_database, "SELECT data FROM mbdiskcache WHERE id = ?", -1, &_queryStatement, NULL);
	
	NSData *data = nil;
	if (_queryStatement != NULL)
	{
		sqlite3_bind_int64(_queryStatement, 1, [ticket.cacheID longLongValue]);
		if (sqlite3_step(_queryStatement) == SQLITE_ROW)
			data = [NSData dataWithBytes:sqlite3_column_blob(_queryStatement, 0) length:sqlite3_column_bytes(_queryStatement, 0)];
		sqlite3_reset(_queryStatement);
		sqlite3_clear_bindings(_queryStatement);
	}
	
	if (data == nil)
		DLog(@"MBDiskCache could not fetch data from database!");
	return data;
}

- (BOOL)setData:(NSData *)data forTicket:(MBDiskCacheTicket *)ticket;
{
	if (data == nil || ticket == nil)
		[NSException raise:NSInvalidArgumentException format:@""];
		
	if (_setStatement == NULL)
		sqlite3_prepare_v2(_database, "INSERT OR REPLACE INTO mbdiskcache (id, data) values (?, ?)", -1, &_setStatement, NULL);
		
	if (_setStatement != NULL)
	{
		sqlite3_bind_int64(_setStatement, 1, [ticket.cacheID longLongValue]);
		sqlite3_bind_blob(_setStatement, 2, [data bytes], (int)[data length], SQLITE_STATIC);
		int result = sqlite3_step(_setStatement);
		sqlite3_reset(_setStatement);
		sqlite3_clear_bindings(_setStatement);
		if (result == SQLITE_DONE)
		{
			ticket.datestamp = [NSDate date];
			return YES;
		}
	}
	
	DLog(@"MBDiskCache could not set data in database!");
	return NO;
}

- (BOOL)removeDataForTicket:(MBDiskCacheTicket *)ticket;
{
	if (ticket == nil)
		[NSException raise:NSInvalidArgumentException format:@""];

	if ([self removeDataForCacheID:ticket.cacheID] == YES)
		return YES;
		
	DLog(@"MBDiskCache could not remove data from database!");
	return NO;
}

- (BOOL)collectGarbage;
{	
	if (_listStatement == NULL)
		sqlite3_prepare_v2(_database, "SELECT id FROM mbdiskcache", -1, &_listStatement, NULL);
	
	if (_listStatement != NULL)
	{
		NSMutableArray *cacheIDsToDelete = [[NSMutableArray alloc] init];
		[self beginTransaction];
		int result;
		while ((result = sqlite3_step(_listStatement)) == SQLITE_ROW)
		{
			NSNumber *cacheID = [[NSNumber alloc] initWithLongLong:sqlite3_column_int64(_listStatement, 0)];
			if ([[MBDiskCacheTicket numberOfTicketsByCacheID] objectForKey:cacheID] == nil)
				[cacheIDsToDelete addObject:cacheID];
			[cacheID release];
		}
		sqlite3_reset(_listStatement);
		
		if (result == SQLITE_DONE)
		{
			for (NSNumber *cacheID in cacheIDsToDelete)
			{
				if ([self removeDataForCacheID:cacheID] == NO)
				{
					result = SQLITE_ERROR;
					break;
				}
			}
		}
		[cacheIDsToDelete release];
		[self commitTransaction];
		if (result == SQLITE_DONE)
			return YES;
	}
	
	DLog(@"MBDiskCache garbage collection failed!");
	return NO;
}

- (void)beginTransaction;
{
	if (_beginTransactionStatement == NULL)
		sqlite3_prepare_v2(_database, "BEGIN TRANSACTION", -1, &_beginTransactionStatement, NULL);
	
	if (_beginTransactionStatement != NULL)
	{
		int result = sqlite3_step(_beginTransactionStatement);
		sqlite3_reset(_beginTransactionStatement);
		if (result == SQLITE_DONE)
			return;
	}
	
	DLog(@"MBDiskCache could not begin transaction!");
}

- (void)commitTransaction;
{
	if (_commitTransactionStatement == NULL)
		sqlite3_prepare_v2(_database, "COMMIT TRANSACTION", -1, &_commitTransactionStatement, NULL);
	
	if (_commitTransactionStatement != NULL)
	{
		int result = sqlite3_step(_commitTransactionStatement);
		sqlite3_reset(_commitTransactionStatement);
		if (result == SQLITE_DONE)
			return;
	}
	
	DLog(@"MBDiskCache could not commit transaction!");
}

//  MBDiskCache ()
- (BOOL)removeDataForCacheID:(NSNumber *)cacheID;
{
	NSParameterAssert(cacheID);
	
	if (_deleteStatement == NULL)
		sqlite3_prepare_v2(_database, "DELETE FROM mbdiskcache WHERE id = ?", -1, &_deleteStatement, NULL);
	
	if (_deleteStatement != NULL)
	{
		sqlite3_bind_int64(_deleteStatement, 1, [cacheID longLongValue]);
		int result = sqlite3_step(_deleteStatement);
		sqlite3_reset(_deleteStatement);
		sqlite3_clear_bindings(_deleteStatement);
		if (result == SQLITE_DONE)
			return YES;
	}
	return NO;
}

@end
