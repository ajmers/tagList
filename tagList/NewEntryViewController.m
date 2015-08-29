//
//  NewEntryViewController.m
//  tagList
//
//  Created by Anne Maiale on 8/25/15.
//  Copyright (c) 2015 Anne Maiale. All rights reserved.
//

#import "NewEntryViewController.h"
#import "TLitem.h"
#import "TLtag.h"
#import "CoreDataStack.h"

@interface NewEntryViewController ()

@property (strong, nonatomic) IBOutlet UITextField *textField;

@end

@implementation NewEntryViewController



- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    
 // Pass the selected object to the new view controller.
}
*/
-(void)dismissSelf {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}


-(void)insertListItem {
    CoreDataStack *coreDataStack = [CoreDataStack defaultStack];
    TLitem *entry = [NSEntityDescription insertNewObjectForEntityForName:@"TLitem"
                                                  inManagedObjectContext:coreDataStack.managedObjectContext];
    NSString *content = self.textField.text;
    NSString *pattern = @"(#[\\S]+)+";
    NSError *error = NULL;
    NSRegularExpression *regex = [NSRegularExpression
                                  regularExpressionWithPattern:pattern
                                  options:NSRegularExpressionCaseInsensitive
                                  error:&error];
    
    
    NSString *contentNoTags = [regex stringByReplacingMatchesInString:content options:0 range:NSMakeRange(0, [content length]) withTemplate:@""];
    NSString *trimmedContentNoTags = [contentNoTags stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    [entry setText:trimmedContentNoTags];
    
    NSArray *tagsArray = [regex matchesInString:content options:0 range:NSMakeRange(0, [content length])];
    NSSet* tagsSet = [[NSSet alloc] initWithArray:tagsArray];
    //[entry addTags:tagsSet];
    
    NSMutableArray *matches = [NSMutableArray arrayWithCapacity:[tagsArray count]];

    for (NSTextCheckingResult *match in tagsArray) {
        NSRange matchRange = [match rangeAtIndex:1];
        TLtag *tag = [NSEntityDescription insertNewObjectForEntityForName:@"TLtag"
                                                      inManagedObjectContext:coreDataStack.managedObjectContext];
        NSString* tagName = [content substringWithRange:matchRange];
        [tag setText:tagName];
        [entry addTagsObject:tag];
        [tag addItemsObject:entry];
    }
    
    [coreDataStack saveContext];

    
}

- (IBAction)doneWasPressed:(id)sender {
    [self insertListItem];
    [self dismissSelf];
}

- (IBAction)cancelWasPressed:(id)sender {
    [self dismissSelf];
}

@end
