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
@property (nonatomic) BOOL shouldReplaceOneExtraChar;
@property (nonatomic) NSRegularExpression *tagRegex;

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

    BOOL shouldReset = NO;
    _shouldReplaceOneExtraChar = YES;
    
    if ([string isEqualToString:@"#"]) {
        NSLog(@"starting tag.");
        _tagRange = NSMakeRange (range.location, 0);
        _isTypingTag = YES;
        shouldReset = YES;
    // character is a space after a tag
    } else if (_isTypingTag && [string isEqualToString:@" "]) {
        NSLog(@"Space, setting typingTag to no.");
        _isTypingTag = NO;
        shouldReset = true;
    // user input more than one letter, such by pasting.
    } else if (string.length > 1 && [self validateString:_textField.text]) {
        NSLog(@"Multiple");
        _isTypingTag = YES;
    // backspace and removed hashtag
    } else if (string.length == 0 && _tagRange.location == range.location) {
        NSLog(@"Backspaced past beginning of tag");
        _isTypingTag = NO;
    } else if (string.length == 0) {
        _shouldReplaceOneExtraChar = NO;
        shouldReset = YES;
    }
    
    if (_isTypingTag) {
        _tableView.hidden = false;
        if (shouldReset) {
            [self resetMatchingTagsArray];
        }

        _tagRange.length = range.location - _tagRange.location;
        NSLog(@"Updated tag length.");
        NSString* textFieldText = [[NSString alloc] initWithString:textField.text];
        NSMutableString *currentTagText = [[NSMutableString alloc] init];
        currentTagText = [textFieldText substringWithRange:_tagRange];
                                                                   
        [self searchAutocompleteEntriesWithSubstring:currentTagText andString:string];
    } else {
        _tableView.hidden = true;
    }
    [_tableView reloadData];
    
    return YES;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath
                                                                    *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    NSString *tag = [NSString stringWithString:cell.textLabel.text];
    
    NSMutableString *textFieldText = [[NSMutableString alloc] init];
    textFieldText = [NSMutableString stringWithString:_textField.text];
    NSLog(textFieldText);
    NSLog(tag);
    
    NSInteger *tagReplaceLength = _shouldReplaceOneExtraChar ? _tagRange.length + 1 : _tagRange.length;
    NSRange replaceRange = NSMakeRange(_tagRange.location, tagReplaceLength);
    [textFieldText replaceCharactersInRange:replaceRange withString:tag];
    [textFieldText appendString:@" "];
    _tagRange.length = tag.length;
    [_textField setText: textFieldText];
}

- (BOOL)validateString:(NSString *)string
{
    NSLog(@"%@", string);
    NSError *error = nil;
    if (!_tagRegex) {
        NSString *pattern = @"\\s#[\\S]*$";
        _tagRegex = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:&error];
    }
    
    NSAssert(_tagRegex, @"Unable to create regular expression");
    
    NSRange textRange = NSMakeRange(0, string.length);
    NSRange matchRange = [_tagRegex rangeOfFirstMatchInString:string options:NSMatchingReportProgress range:textRange];
    
    BOOL didValidate = NO;
    
    // Did we find a matching range
    if (matchRange.location != NSNotFound)
        didValidate = YES;
    
    return didValidate;
}


- (void)searchAutocompleteEntriesWithSubstring:(NSString *)substring andString:(NSString*)string {
    NSMutableArray *autocompleteTags = [[NSMutableArray alloc] initWithArray:_matchingTagsArray];
    
    NSLog(substring);
    if (substring.length) {
        // Put anything that contains this substring into the autocomplete array
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
