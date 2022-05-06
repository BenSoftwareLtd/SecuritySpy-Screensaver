//
//  MBDiskCache.h
//  SecuritySpy
//
//  Requires libsqlite3.dylib
//
//  Created by Milo on 18/03/2008.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>
#import "MBDiskCacheTicket.h"


@interface MBDiskCache : NSObject
{
	sqlite3			*_database;
	sqlite3_stmt	*_addStatement;
	sqlite3_stmt	*_queryStatement;
	sqlite3_stmt	*_setStatement;
	sqlite3_stmt	*_deleteStatement;
	sqlite3_stmt	*_listStatement;
	sqlite3_stmt	*_beginTransactionStatement;
	sqlite3_stmt	*_commitTransactionStatement;
}

- (id)initWithPath:(NSString *)path;		//  Returns nil if the disk cache could not be created and/or opened. Raises an exception if path is nil.

- (MBDiskCacheTicket *)addData:(NSData *)data;							//  Returns a unique ticket for the data, or nil if it could not be cached.
- (NSData *)dataForTicket:(MBDiskCacheTicket *)ticket;
- (BOOL)setData:(NSData *)data forTicket:(MBDiskCacheTicket *)ticket;	//  Replaces an existing entry if necessary. Updates the ticket's datestamp.
- (BOOL)removeDataForTicket:(MBDiskCacheTicket *)ticket;

- (BOOL)collectGarbage;      //  removes any data from the cache for which a corresponding MBDiskCacheTicket is not currently instantiated.

- (void)beginTransaction;
- (void)commitTransaction;
@end