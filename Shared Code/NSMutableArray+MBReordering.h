//
//  NSMutableArray+MBReordering.h
//  SecuritySpy
//
//  Created by Milo on 10/08/2007.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSMutableArray (MBReordering)

- (void)moveObjectAtIndex:(NSUInteger)index toIndex:(NSUInteger)newIndex;
- (void)moveObjectsFromIndexSet:(NSIndexSet *)indexSet toIndex:(NSUInteger)newIndex;
@end
