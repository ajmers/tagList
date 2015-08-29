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

@interface NewEntryViewController () <UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) IBOutlet UITextField *textField;
@property (strong, nonatomic) NSFetchedResultsController* existingTagsFetchedResultsController;
@end

@implementation NewEntryViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.existingTagsFetchedResultsController performFetch:nil];
    

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


// Parsing text and adding item & tags.

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
        NSString* tagName = [content substringWithRange:matchRange];
        
        TLtag *existingTag = [self getExistingTag:tagName];
        
        TLtag *tag = (existingTag != nil) ? existingTag : [NSEntityDescription insertNewObjectForEntityForName:@"TLtag"
                inManagedObjectContext:coreDataStack.managedObjectContext];

        if (!!existingTag) {
            [tag addItemsObject:entry];
        } else {
            [tag addItemsObject:entry];
            [tag setText:tagName];
            [entry addTagsObject:tag];
        }
    }
    
    [coreDataStack saveContext];
}

- (TLtag *)getExistingTag:(NSString *)tagName {
    NSArray *existingTags = self.existingTagsFetchedResultsController.fetchedObjects;
    
    for (TLtag *item in existingTags) {
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"text MATCHES %@", tagName];
        NSArray *filteredArray = [existingTags filteredArrayUsingPredicate:predicate];
        if ([filteredArray count] > 0) {
            return [filteredArray objectAtIndex:0];
        }
    }
    return nil;
    
}

- (NSFetchRequest *)existingTagsFetchRequest {
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"TLtag"];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"text" ascending:NO];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    return fetchRequest;
}

- (NSFetchedResultsController *)existingTagsFetchedResultsController {
    if (_existingTagsFetchedResultsController != nil) {
        return _existingTagsFetchedResultsController;
    }
    
    CoreDataStack *coreDataStack = [CoreDataStack defaultStack];
    NSFetchRequest *existingTagsFetchRequest = [self existingTagsFetchRequest];
    
    _existingTagsFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:existingTagsFetchRequest managedObjectContext:coreDataStack.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
    _existingTagsFetchedResultsController.delegate = self;
    
    return _existingTagsFetchedResultsController;
}

- (IBAction)doneWasPressed:(id)sender {
    [self insertListItem];
    [self dismissSelf];
}

- (IBAction)cancelWasPressed:(id)sender {
    [self dismissSelf];
}

@end
