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
@property (nonatomic, retain) NSSet *tags;
@end

@interface TLitem (CoreDataGeneratedAccessors)

- (void)addTagsObject:(TLtag *)value;
- (void)removeTagsObject:(TLtag *)value;
- (void)addTags:(NSSet *)values;
- (void)removeTags:(NSSet *)values;

@end
