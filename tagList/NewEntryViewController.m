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
    NSArray* tagsList = [self.existingTagsFetchedResultsController fetchedObjects];
    _matchingTagsArray = [[NSMutableArray alloc] initWithArray:tagsList];
    NSLog(@"matching tags array was created.");
}

-(void)resetMatchingTagsArray {
    if ([_matchingTagsArray count] != [[self.existingTagsFetchedResultsController fetchedObjects] count]) {
        // When backspace is pressed, reset matchingTagsArray to retrieve ALL tags, then be
        [self createMatchingTagsArray];
        NSLog(@"matching tags array was reset.");
    } else {
        NSLog(@"ALREADY reset.");
    }
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
    
    NSLog(string);
    if (textField.text.length == 0) {
        _isTypingTag = NO;
        [self resetMatchingTagsArray];
        return YES;
    } else {
        NSString *pattern = @"\s#[\S]+$";
        NSPredicate *isTypingTag = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", pattern];
        
        if ([isTypingTag evaluateWithObject: self.textField.text]){
            _isTypingTag = NO;
        }
    }
    if ([string isEqualToString:@"#"]) {
        NSLog(@"#, starting hashtag.");
        [self resetMatchingTagsArray];
        _isTypingTag = YES;
        _tableView.hidden = NO;
        _tagRange = NSMakeRange (range.location, 0);
        [self resetMatchingTagsArray];
    } else if ([string isEqualToString:@" "]) {
            NSLog(@"space, set typingTag to NO.");
            _isTypingTag = NO;
            _tableView.hidden = YES;
        
    } else if (_isTypingTag) {
        if (range.length==1 && string.length==0) {
            NSLog(@"backspace, reset results.");
            [self resetMatchingTagsArray];
        }
        _tagRange.length = range.location - _tagRange.location;
        
        NSMutableString *fullTagSoFar = [NSMutableString stringWithString:_textField.text];
        fullTagSoFar = [[fullTagSoFar substringWithRange:_tagRange] stringByAppendingString:string];

        [self searchAutocompleteEntriesWithSubstring:fullTagSoFar];
    }
    [_tableView reloadData];
    
    return YES;
}

- (void)searchAutocompleteEntriesWithSubstring:(NSString *)substring {
    NSMutableArray *autocompleteTags = [[NSMutableArray alloc] initWithArray:_matchingTagsArray];
    NSLog(substring);
    if (substring.length) {
        // Put anything that contains with this substring into the autocompleteUrls array
        // The items in this array is what will show up in the table view
        for(TLtag *curTag in _matchingTagsArray) {
            NSString *curString = [curTag valueForKey:@"text"];
            NSRange substringRange = [curString rangeOfString:substring];
            if (substringRange.location != 0) {
                //NSLog(@'tag %@ found in existingTags', substring);
                
                [autocompleteTags removeObject:curTag];
            }
        }
        _matchingTagsArray = autocompleteTags;
    }
    if ([_matchingTagsArray count] == 0) {
        _tableView.hidden = true;
    }
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
    return _matchingTagsArray.count;
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
