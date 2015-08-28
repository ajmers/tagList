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
@property (nonatomic, retain) NSSet *tag_belongs_to_items;
@end

@interface TLtag (CoreDataGeneratedAccessors)

- (void)addTag_belongs_to_itemsObject:(TLitem *)value;
- (void)removeTag_belongs_to_itemsObject:(TLitem *)value;
- (void)addTag_belongs_to_items:(NSSet *)values;
- (void)removeTag_belongs_to_items:(NSSet *)values;

@end
