/***** BEGIN LICENSE BLOCK *****
 Version: MPL 1.1
 
 The contents of this file are subject to the Mozilla Public License Version 
 1.1 (the "License"); you may not use this file except in compliance with 
 the License. You may obtain a copy of the License at 
 http://www.mozilla.org/MPL/
 
 Software distributed under the License is distributed on an "AS IS" basis,
 WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 for the specific language governing rights and limitations under the
 License.
 
 The Original Code is weave-iphone.
 
 The Initial Developer of the Original Code is Mozilla Labs.
 Portions created by the Initial Developer are Copyright (C) 2009
 the Initial Developer. All Rights Reserved.
 
 Contributor(s):
 Anant Narayanan <anant@kix.in>
 Dan Walkowski <dan.walkowski@gmail.com>
 
 ***** END LICENSE BLOCK *****/

#import "SearchResultsController.h"
#import "WebPageController.h"
#import "Store.h"
#import "TapActionController.h"


@interface SearchResultsController (private)
- (void)refreshHits;
@end


@implementation SearchResultsController

@synthesize resultsTable;
@synthesize splashScreen;


- (void)viewDidLoad {
  [super viewDidLoad];
  
  [self.view addSubview:splashScreen.view];
  CGRect frame = splashScreen.view.frame;
  frame.origin.y +=  24;  //status bar height.  this is a temporary kludge
  frame.size.height = 345;  //more kludge, this view sits on top, and not inside, so it must be told how big to be, it cannot ask its parent
  splashScreen.view.frame = frame;
  
 }

- (void) refresh
{
  [resultsTable reloadData];
  [self.searchDisplayController.searchResultsTableView reloadData];
}


- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  [splashScreen viewWillAppear:animated];
}


- (void)viewDidAppear:(BOOL)animated
{  
  [splashScreen viewDidAppear:animated];
}

/*
- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
}
*/
/*
- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
}
*/


- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


#pragma mark Table view methods

//from experience, this is the first delegate method called when the table refreshes its data, so we'll regenerate our dataset now
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
  //sadly works by side-effect, caching the matches in the searchHits array, for use by the other table layout functions
  [self refreshHits];
  
  if (self.searchDisplayController.searchBar.text != nil && self.searchDisplayController.searchBar.text.length != 0)
  {
    [splashScreen.view setHidden:YES];
    return 3;
  }
    
  [splashScreen.view setHidden:NO];
  return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section 
{
  // we are not displaying sections that are empty
  switch (section) {
    case 0:
      if ([[searchHits objectAtIndex:0] count] !=0)
        return @"Tabs";
      else return nil;
      break;
    case 1:
      if ([[searchHits objectAtIndex:1] count] !=0)
        return @"Bookmarks";
      else return nil;
      break;
    case 2:
      if ([[searchHits objectAtIndex:2] count] !=0)
        return @"History";
      else return nil;
      break;
  }
  return @"";
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
  if (self.searchDisplayController.searchBar.text != nil && self.searchDisplayController.searchBar.text.length != 0)
  {
    return [[searchHits objectAtIndex:section] count];
  }
      
  return 0;
}


//Note: this table cell code is nearly identical to the same method in bookmarks and tabs,
// but we want to be able to easily make them display differently, so it is replicated
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"search_results";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
    }
    
    NSDictionary* matchItem = [[searchHits objectAtIndex:[indexPath section]] objectAtIndex:[indexPath row]];
    // Set up the cell...
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    cell.textLabel.minimumFontSize = 13;
    cell.textLabel.text = [matchItem objectForKey:@"title"];
    cell.detailTextLabel.text = [matchItem objectForKey:@"uri"];
//    cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;

    //set it to the default to start
    cell.imageView.image = [[[Store getStore] getFavicons] objectForKey:@"blankfavicon.ico"];
    NSString* iconPath = [matchItem objectForKey:@"icon"];
    
    if (iconPath != nil && [iconPath length] > 0)
    {
      UIImage* favicon = [[[Store getStore] getFavicons] objectForKey:iconPath];
      if (favicon != nil) 
      {
        cell.imageView.image = favicon;
      }    
    }
  
    return cell;
}



- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
  UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
  TapActionController* tap = [[TapActionController alloc] initWithDescription:cell.textLabel.text andLocation:cell.detailTextLabel.text];
  [tap chooseAction];
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
}



- (void)searchBar:(UISearchBar *)theSearchBar textDidChange:(NSString *)searchText 
{
  [splashScreen.view setHidden:YES];
	[resultsTable reloadData];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
  [splashScreen.view setHidden:NO];
  self.searchDisplayController.searchBar.text = nil;
  [resultsTable reloadData];
}



- (void)refreshHits
{
  NSString *searchText = self.searchDisplayController.searchBar.text;

  [searchHits release];
  searchHits  = [[NSArray arrayWithObjects:[NSMutableArray array], [NSMutableArray array], [NSMutableArray array], nil] retain]; 
  
  if (searchText == nil || [searchText length] == 0) return;

  NSDictionary* tabs = [[[Store getStore] getTabs] retain];
	NSArray*  bookmarks = [[[Store getStore] getBookmarks] retain];
  NSArray*  history = [[[Store getStore] getHistory] retain];
  
  
  //tabs are a more complicated structure, need to flatten the results
  for (NSDictionary* client in tabs)
  {
    NSArray* clientTabs = [client objectForKey:@"tabs"];
    for (NSDictionary* aTab in clientTabs)
    {
      NSRange uriRange = [[aTab objectForKey:@"uri"] rangeOfString:searchText options:NSCaseInsensitiveSearch];
      NSRange titleRange = [[aTab objectForKey:@"title"] rangeOfString:searchText options:NSCaseInsensitiveSearch];
      
      if (titleRange.location != NSNotFound || uriRange.location != NSNotFound)
        [[searchHits objectAtIndex:0] addObject:aTab];
      
    }
  }
  
  
  //I want to make these keyed dictionaries like the tabs
  for (NSDictionary* bmk in bookmarks)
  {
    NSRange uriRange = [[bmk objectForKey:@"uri"] rangeOfString:searchText options:NSCaseInsensitiveSearch];
    NSRange titleRange = [[bmk objectForKey:@"title"]  rangeOfString:searchText options:NSCaseInsensitiveSearch];
    
    if (titleRange.location != NSNotFound || uriRange.location != NSNotFound)
      [[searchHits objectAtIndex:1] addObject:bmk];
  }
  
  
  for (NSDictionary* hist in history)
  {
    NSRange uriRange = [[hist objectForKey:@"uri"] rangeOfString:searchText options:NSCaseInsensitiveSearch];
    NSRange titleRange = [[hist objectForKey:@"title"] rangeOfString:searchText options:NSCaseInsensitiveSearch];
    
    if (titleRange.location != NSNotFound || uriRange.location != NSNotFound)
      [[searchHits objectAtIndex:2] addObject:hist];
  }
  
  [tabs release];
  [bookmarks release];
  [history release];
  
}

- (void)dealloc {
    [super dealloc];
}

@end

