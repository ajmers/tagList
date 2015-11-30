//
//  DetailsViewController.m
//  tagList
//
//  Created by Anne Maiale on 9/13/15.
//  Copyright (c) 2015 Anne Maiale. All rights reserved.
//

#import "DetailsViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "UIView+borders.h"
#import "tagPill.h"

#import "TLitem.h"
#import "TLtag.h"

@interface DetailsViewController ()

@property (nonatomic) CGFloat top;

@end

@implementation DetailsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    TLitem *entry = [self entry];
    UIView *container = [self labelContainer];
    UILabel *label = [self entryLabel];
    
    // container.layer.borderWidth=1;
    [container addBottomBorderWithColor:[UIColor lightGrayColor] andWidth:1];
    label.text = [entry valueForKey:@"text"];
    _top = 0;
    
    NSArray *tags = [entry valueForKey:@"tags"];
    for (TLtag *tag in tags) {
        tagPill *tagLabel = [self createPillWithText:[tag valueForKey:@"text"]];
        _top += 50;
        [[self pillsContainerView] addSubview:tagLabel];
    }
}

- (tagPill*)createPillWithText:(NSString *)tag {
    CGSize stringsize = [tag sizeWithFont:[UIFont systemFontOfSize:30]];
    
    tagPill *pill = [[tagPill alloc] init];
    [pill setText: tag];
    [pill setFrame:CGRectMake(40,_top,stringsize.width,stringsize.height)];
    [pill setBackgroundColor:[self generateColorWithSaturation:(CGFloat).5]];

    return pill;
}

- (UIColor *)generateColorWithSaturation:(CGFloat)saturation { //0.5 to 1.0, away from white
    CGFloat hue = ( arc4random() % 256 / 256.0 );  //  0.0 to 1.0
    if (saturation < .5 || saturation >= 1) {
        saturation = ( arc4random() % 128 / 256.0 ) + 0.5;
    }
    CGFloat brightness = ( arc4random() % 128 / 256.0 ) + 0.5;  //  0.5 to 1.0, away from black
    UIColor *color = [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:1];
    return color;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

@end
