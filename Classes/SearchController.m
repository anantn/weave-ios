//
//  SearchController.m
//  Weave
//
//  Created by Anant Narayanan on 6/11/09.
//  Copyright 2009 Mozilla Corporation. All rights reserved.
//

#import "SearchController.h"
#import "WeaveAppDelegate.h"
#import "Service.h"

@implementation SearchController

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
	const NSInteger TITLE_TAG = 1001;
	const NSInteger URI_TAG = 1002;

	UILabel *title;
	UILabel *uri;
	UIImage *star = [UIImage imageNamed:@"Star.png"];
	
	static NSString *CellIdentifier = @"Cell";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:CellIdentifier] autorelease];
		title = [[[UILabel alloc] initWithFrame:CGRectMake(
						cell.indentationWidth,
						tableView.rowHeight - 40,
						tableView.bounds.size.width - cell.indentationWidth - star.size.width - 10,
						20)] autorelease];
		[cell.contentView addSubview:title];
		title.tag = TITLE_TAG;
		title.font = [UIFont systemFontOfSize:[UIFont labelFontSize] + 1];
		
		uri = [[[UILabel alloc] initWithFrame:CGRectMake(
						cell.indentationWidth,
						tableView.rowHeight - 20,
						tableView.bounds.size.width - cell.indentationWidth - star.size.width - 10,
						15)] autorelease];
		[cell.contentView addSubview:uri];
		uri.tag = URI_TAG;
		uri.font = [UIFont systemFontOfSize:[UIFont labelFontSize] - 3];
		uri.textColor = [UIColor colorWithRed:0.34 green:0.50 blue:0.77 alpha:1.0];
	} else {
		title = (UILabel *)[cell viewWithTag:TITLE_TAG];
		uri = (UILabel *)[cell viewWithTag:URI_TAG];
	}
	
	cell.accessoryView = nil;
	// Set up the cell...
	@try {
		if (searching) {
			if (indexPath.row >= [bmkList count]) {
				title.text = [[histList objectAtIndex:(indexPath.row - [bmkList count])] objectAtIndex:0];
				uri.text = [[histList objectAtIndex:(indexPath.row - [bmkList count])] objectAtIndex:1];
			} else {
				title.text = [[bmkList objectAtIndex:indexPath.row] objectAtIndex:0];
				uri.text = [[bmkList objectAtIndex:indexPath.row] objectAtIndex:1];
				cell.accessoryView = [[[UIImageView alloc] initWithImage:star] autorelease];
			}
		} else {
			title.text = [[[app service] getBookmarkTitles] objectAtIndex:indexPath.row];
			uri.text = [[[app service] getBookmarkURIs] objectAtIndex:indexPath.row];
		}
	} @catch (id theException) {
		NSLog(@"%@ threw %@", indexPath.row, theException);
	}
	
	return cell;
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {	
	[self tableView:tableView didSelectRowAtIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (searching) {
		if (indexPath.row >= [bmkList count]) {
			[app setUri:[[histList objectAtIndex:(indexPath.row - [bmkList count])] objectAtIndex:1]];
		} else {
			[app setUri:[[bmkList objectAtIndex:indexPath.row] objectAtIndex:1]];
		}
	} else {
		[app setUri:[[[app service] getBookmarkURIs] objectAtIndex:indexPath.row]];
	}
	
	[app flipToWebFrom:self.view];
}

/* Search bar */
- (void) searchBarTextDidBeginEditing:(UISearchBar *)theSearchBar {
	searching = YES;
}

- (void)searchBar:(UISearchBar *)theSearchBar textDidChange:(NSString *)searchText {
	// Remove all objects first.
	[bmkList removeAllObjects];
	[histList removeAllObjects];
	
	if ([searchText length] > 0) {
		searching = YES;
		[self searchTableView];
	} else {
		searching = NO;
	}
	
	[self.tableView reloadData];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)theSearchBar {
	searchBar.text = @"";
	searching = NO;
	[searchBar resignFirstResponder];
	[self.tableView reloadData];
}

- (void)searchTableView {
	int i;
	NSString *searchText = searchBar.text;
	[bmkList removeAllObjects];
	[histList removeAllObjects];

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
	
	/* History search */
	for (i = 0; i < [hiT count]; i++) {
		NSString *uri = [hiU objectAtIndex:i];
		NSString *title = [hiT objectAtIndex:i];
		
		NSRange hu = [uri rangeOfString:searchText options:NSCaseInsensitiveSearch];
		NSRange ht = [title rangeOfString:searchText options:NSCaseInsensitiveSearch];
		
		if (hu.length > 0 || ht.length > 0) {
			[histList addObject:[NSArray arrayWithObjects:title, uri, nil]];
		}
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
