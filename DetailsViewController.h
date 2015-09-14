//
//  DetailsViewController.h
//  tagList
//
//  Created by Anne Maiale on 9/13/15.
//  Copyright (c) 2015 Anne Maiale. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TLitem.h"

@interface DetailsViewController : UIViewController

@property (nonatomic, strong) TLitem *entry;

@property (weak, nonatomic) IBOutlet UILabel *entryLabel;

@end
