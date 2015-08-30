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

@interface NewEntryViewController () <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>

@property (strong, nonatomic) IBOutlet UITextField *textField;
@property (strong, nonatomic) IBOutlet UITableView* tableView;

@property (strong, nonatomic) NSFetchedResultsController* existingTagsFetchedResultsController;
@property (strong, nonatomic) NSMutableArray *matchingTagsArray;

@property (nonatomic) NSRange tagRange;
@property (nonatomic) BOOL isTypingTag;

@end

@implementation NewEntryViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[self textField] setDelegate:self];
    [self.existingTagsFetchedResultsController performFetch:nil];
    [self createMatchingTagsArray];
    [self createAutocompleteTableView];

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

-(void)createMatchingTagsArray {
//    NSPredicate *pre = [NSPredicate predicateWithFormat:@"attribute CONTAINS [cd] %@", searchString];
//    NSArray *searchResults = [[self.fetchedResultsController fetchedObjects] filteredArrayUsingPredicate:pre]

    
    
    NSArray* tagsList = [self.existingTagsFetchedResultsController fetchedObjects];
    _matchingTagsArray = [[NSMutableArray alloc] initWithArray:tagsList];
}

-(void)createAutocompleteTableView {
    UITableView* autocompleteTableView = _tableView;
    autocompleteTableView.delegate = self;
    autocompleteTableView.dataSource = self;
    autocompleteTableView.scrollEnabled = YES;
    autocompleteTableView.hidden = YES;
    [self.view addSubview:autocompleteTableView];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    //Check if the current character (string) is #. If so, set _tagBeginRange to [range.location, 0]; increment the
    // range.length as we continue typing.

    if ([string isEqualToString:@"#"]) {
        _isTypingTag = YES;
        _tableView.hidden = NO;
        _tagRange = NSMakeRange (range.location, 0);

    } else if (_isTypingTag) {
        
        _tagRange.length = range.location - _tagRange.location;
        NSString *substring = [textField.text substringWithRange:_tagRange];
//        NSString *substring = [NSString stringWithString:textField.text];
//        substring = [substring
//                     stringByReplacingCharactersInRange:_tagBeginRange withString:string];
        
        [self searchAutocompleteEntriesWithSubstring:substring];
    }
    
    return YES;
}

- (void)searchAutocompleteEntriesWithSubstring:(NSString *)substring {
    NSMutableArray *autocompleteTags = [[NSMutableArray alloc] init];
    
    // Put anything that contains with this substring into the autocompleteUrls array
    // The items in this array is what will show up in the table view
    for(TLtag *curTag in _matchingTagsArray) {
        NSString *curString = [curTag valueForKey:@"text"];
        NSRange substringRange = [curString rangeOfString:substring];
        if (substringRange.location != 0) {
            [autocompleteTags removeObject:curTag];
        }
    }
    _matchingTagsArray = autocompleteTags;
    [_tableView reloadData];
}

// Autocompleting search table
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"Cell"];
    }
    // Configure the cell...
    TLtag *tag = [self.matchingTagsArray objectAtIndex:indexPath.row];
    cell.textLabel.text = tag.text;
    
    return cell;
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _existingTagsFetchedResultsController.fetchedObjects.count;
};






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
