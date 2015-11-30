//
//  tagPill.m
//  tagList
//
//  Created by Anne Maiale on 11/29/15.
//  Copyright © 2015 Anne Maiale. All rights reserved.
//

#import "tagPill.h"

#define PADDING 8.0
#define CORNER_RADIUS 4.0

@implementation tagPill

- (void)drawRect:(CGRect)rect {
    self.layer.masksToBounds = YES;
    self.layer.cornerRadius = CORNER_RADIUS;
    UIEdgeInsets insets = {0, PADDING, 0, 0};
    return [super drawTextInRect:UIEdgeInsetsInsetRect(rect, insets)];
}
- (CGSize) intrinsicContentSize {
    CGSize intrinsicSuperViewContentSize = [super intrinsicContentSize] ;
    intrinsicSuperViewContentSize.width += PADDING * 2 ;
    return intrinsicSuperViewContentSize ;
}

@end
