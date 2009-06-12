//
//  BookmarksController.m
//  Weave
//
//  Created by Anant Narayanan on 6/11/09.
//  Copyright 2009 Mozilla Corporation. All rights reserved.
//

#import "BookmarksController.h"
#import "WeaveAppDelegate.h"
#import "Service.h"

@implementation BookmarksController

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];

	app = (WeaveAppDelegate *)[[UIApplication sharedApplication] delegate];
	bmkList = [[NSMutableArray alloc] init];
	histList = [[NSMutableArray alloc] init];
	
	self.tableView.tableHeaderView = searchBar;
	searchBar.autocorrectionType = UITextAutocorrectionTypeNo;
	searching = NO;
	letUserSelectRow = YES;
	//Set the title
	self.navigationItem.title = @"Bookmarks";
}

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {    
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (searching)
		return [bmkList count] + [histList count];
	else
		return [[[app service] getBookmarkTitles] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if (searching)
		return @"Search Results";
	else
		return @"Bookmarks";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *CellIdentifier = @"Cell";
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:CellIdentifier] autorelease];
	}
	
	// Set up the cell...
	if (searching) {
		if (indexPath.row >= [bmkList count])
			cell.text = [[histList objectAtIndex:(indexPath.row - [bmkList count])] objectAtIndex:0];
		else
			cell.text = [[bmkList objectAtIndex:indexPath.row] objectAtIndex:0];
	} else {
		cell.text = [[[app service] getBookmarkTitles] objectAtIndex:indexPath.row];
	}
	
	return cell;
}

- (NSIndexPath *)tableView :(UITableView *)theTableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (letUserSelectRow)
		return indexPath;
	else
		return nil;
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {	
	[self tableView:tableView didSelectRowAtIndexPath:indexPath];
}

/* Search bar */
- (void) searchBarTextDidBeginEditing:(UISearchBar *)theSearchBar {
	NSLog(@"Search begun");
	searching = YES;
	letUserSelectRow = NO;
	self.tableView.scrollEnabled = NO;
	
	/*
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] 
											   initWithBarButtonSystemItem:UIBarButtonSystemItemDone 
											   target:self action:@selector(doneSearching_Clicked:)] autorelease];
	*/
}

- (void)searchBar:(UISearchBar *)theSearchBar textDidChange:(NSString *)searchText {
	// Remove all objects first.
	[bmkList removeAllObjects];
	[histList removeAllObjects];
	
	if ([searchText length] > 0) {
		searching = YES;
		letUserSelectRow = YES;
		self.tableView.scrollEnabled = YES;
		[self searchTableView];
	} else {
		searching = NO;
		letUserSelectRow = NO;
		self.tableView.scrollEnabled = NO;
	}
	
	[self.tableView reloadData];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)theSearchBar {
	searchBar.text = @"";
	[searchBar resignFirstResponder];
	
	letUserSelectRow = YES;
	searching = NO;
	self.navigationItem.rightBarButtonItem = nil;
	self.tableView.scrollEnabled = YES;
	
	[self.tableView reloadData];
}

- (void)searchTableView {
	int i;
	NSString *searchText = searchBar.text;

	NSArray *bmT = [[app service] getBookmarkTitles];
	NSArray *bmU = [[app service] getBookmarkURIs];
	NSArray *hiT = [[app service] getHistoryTitles];
	NSArray *hiU = [[app service] getHistoryURIs];
	
	/* Bookmark search */
	for (i = 0; i < [bmT count]; i++) {
		NSString *uri = [bmU objectAtIndex:i];
		NSString *title = [bmT objectAtIndex:i];
		
		NSRange ru = [uri rangeOfString:searchText options:NSCaseInsensitiveSearch];
		NSRange rt = [title rangeOfString:searchText options:NSCaseInsensitiveSearch];
		
		if (ru.length > 0 || rt.length > 0)
			[bmkList addObject:[NSArray arrayWithObjects:title, uri, nil]];
	}
	
	for (i = 0; i < [hiT count]; i++) {
		NSString *uri = [hiU objectAtIndex:i];
		NSString *title = [hiT objectAtIndex:i];
		
		NSRange hu = [uri rangeOfString:searchText options:NSCaseInsensitiveSearch];
		NSRange ht = [title rangeOfString:searchText options:NSCaseInsensitiveSearch];
		
		if (hu.length > 0 || ht.length > 0)
			[histList addObject:[NSArray arrayWithObjects:title, uri, nil]];
	}
}

/* Other */
- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}

- (void)dealloc {
	[bmkList release];
	[histList release];
    [super dealloc];
}


@end
