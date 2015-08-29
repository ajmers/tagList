//
//  TLtag.h
//  tagList
//
//  Created by Anne Maiale on 8/17/15.
//  Copyright (c) 2015 Anne Maiale. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class TLitem;

@interface TLtag : NSManagedObject

@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) NSSet *items;
@end

@interface TLtag (CoreDataGeneratedAccessors)

- (void)addItemsObject:(TLitem *)value;
- (void)removeItemsObject:(TLitem *)value;
- (void)addItems:(NSSet *)values;
- (void)removeItems:(NSSet *)values;

@end
