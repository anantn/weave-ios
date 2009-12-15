//
//  SearchResultsController.m
//  Weave
//
//  Created by Dan Walkowski on 11/19/09.
//  Copyright 2009 ClownWare. All rights reserved.
//

#import "SearchResultsController.h"
#import "WebPageController.h"
#import "WeaveAppDelegate.h"
#import "Store.h"

@interface SearchResultsController (private)
- (void)refreshHits;
@end


@implementation SearchResultsController

@synthesize resultsTable;
@synthesize fancyGraphic;




- (void)viewDidLoad {
  [super viewDidLoad];
  self.searchDisplayController.searchBar.barStyle = UIBarStyleBlack;
  self.searchDisplayController.searchBar.translucent = YES;

  self.searchDisplayController.searchBar.showsCancelButton = NO;
 }


/*
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
  
}
 */

- (void)viewDidAppear:(BOOL)animated
{
	[resultsTable deselectRowAtIndexPath:[resultsTable indexPathForSelectedRow] animated: YES];
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

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
  //sadly works by side-effect, caching the matches in the searchHits array, for use by the other table layout functions
  [self refreshHits];
  
  if (self.searchDisplayController.searchBar.text != nil && self.searchDisplayController.searchBar.text.length != 0)
  {
    return 3;
  }
    
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


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"search_results";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
    }
    
    NSDictionary* matchItem = [[searchHits objectAtIndex:[indexPath section]] objectAtIndex:[indexPath row]];
    // Set up the cell...
    cell.textLabel.text = [matchItem objectForKey:@"title"];
    cell.detailTextLabel.text = [matchItem objectForKey:@"uri"];
    cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
    //this should really be the icon from the db, I've left the code down below for later use
    //  theIcon = [tabItem objectForKey:@"icon"];
    cell.imageView.image = [UIImage imageNamed:@"Star.png"];
	
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
  UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
  [[UIApplication sharedApplication] openURL:[NSURL URLWithString:cell.detailTextLabel.text]];
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
  UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
  NSURL* destination = [NSURL URLWithString:cell.detailTextLabel.text];

  WebPageController* webPage = [[WebPageController alloc] initWithURL:destination];
  WeaveAppDelegate* appDelegate = (WeaveAppDelegate *)[[UIApplication sharedApplication] delegate];
  
  [[appDelegate rootController] presentModalViewController: webPage animated:YES];
  [webPage release];
}


- (void)searchBar:(UISearchBar *)theSearchBar textDidChange:(NSString *)searchText 
{
	[resultsTable reloadData];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
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
  for (NSArray* bmk in bookmarks)
  {
    NSString* title = [bmk objectAtIndex:1];
    NSString* uri = [bmk objectAtIndex:0];
    
    NSRange uriRange = [uri rangeOfString:searchText options:NSCaseInsensitiveSearch];
    NSRange titleRange = [title rangeOfString:searchText options:NSCaseInsensitiveSearch];
    
    if (titleRange.location != NSNotFound || uriRange.location != NSNotFound)
      [[searchHits objectAtIndex:1] addObject:[NSDictionary dictionaryWithObjectsAndKeys:title, @"title", uri, @"uri", nil]];
  }
  
  for (NSArray* hist in history)
  {
    NSString* title = [hist objectAtIndex:1];
    NSString* uri = [hist objectAtIndex:0];

    NSRange uriRange = [[hist objectAtIndex:0] rangeOfString:searchText options:NSCaseInsensitiveSearch];
    NSRange titleRange = [[hist objectAtIndex:1] rangeOfString:searchText options:NSCaseInsensitiveSearch];
    
    if (titleRange.location != NSNotFound || uriRange.location != NSNotFound)
      [[searchHits objectAtIndex:2] addObject:[NSDictionary dictionaryWithObjectsAndKeys:title, @"title", uri, @"uri", nil]];
  }
  
  [tabs release];
  [bookmarks release];
  [history release];
  
}

- (void)dealloc {
    [super dealloc];
}





//get the correct icon 
//NSArray *obj;
//    NSDictionary *icons = [[Store getStore] getFavicons];
//    if (indexPath.row >= [bmkList count]) {
//      obj = [histList objectAtIndex:(indexPath.row - [bmkList count])];
//      title.text = [obj objectAtIndex:0];
//      uri.text = [obj objectAtIndex:1];
//      if ([icons objectForKey:[obj objectAtIndex:2]] != nil) {
//        cell.imageView.image = [UIImage imageWithData:[[[NSData alloc]
//                                                        initWithBase64EncodedString:[icons objectForKey:[obj objectAtIndex:2]]] autorelease]];
//      } else {
//        cell.imageView.image = [UIImage imageNamed:@"Document.png"];
//      }
//    } else {
//      obj = [bmkList objectAtIndex:indexPath.row];
//      title.text = [obj objectAtIndex:0];
//      uri.text = [obj objectAtIndex:1];
//      cell.imageView.image = [UIImage imageNamed:@"Star.png"];
//    }

@end

