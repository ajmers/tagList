//
//  UIView+borders.h
//  tagList
//
//  Created by Anne Maiale on 11/29/15.
//  Copyright © 2015 Anne Maiale. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (borders)

- (void)addTopBorderWithColor:(UIColor *)color andWidth:(CGFloat) borderWidth;
- (void)addBottomBorderWithColor:(UIColor *)color andWidth:(CGFloat) borderWidth;
- (void)addLeftBorderWithColor:(UIColor *)color andWidth:(CGFloat) borderWidth;
- (void)addRightBorderWithColor:(UIColor *)color andWidth:(CGFloat) borderWidth;

@end
