//
//  TLitem.h
//  tagList
//
//  Created by Anne Maiale on 8/17/15.
//  Copyright (c) 2015 Anne Maiale. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class TLtag;

@interface TLitem : NSManagedObject

@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) NSSet *item_has_tags;
@end

@interface TLitem (CoreDataGeneratedAccessors)

- (void)addItem_has_tagsObject:(TLtag *)value;
- (void)removeItem_has_tagsObject:(TLtag *)value;
- (void)addItem_has_tags:(NSSet *)values;
- (void)removeItem_has_tags:(NSSet *)values;

@end
