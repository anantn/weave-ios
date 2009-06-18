//
//  RecentController.m
//  Weave
//
//  Created by Anant Narayanan on 6/16/09.
//  Copyright 2009 Mozilla Corporation. All rights reserved.
//

#import "ListController.h"
#import "WeaveAppDelegate.h"
#import "Service.h"

@implementation ListController

@synthesize tView;

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
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {    
	return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	return [app currentList];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if ([[app currentList] isEqualToString:@"Bookmarks"])
		return [[[app service] getBookmarkURIs] count];
	else if ([[app currentList] isEqualToString:@"Tabs"])
		return [[[app service] getTabURIs] count];
	else
		return ([[[app service] getHistoryURIs] count] > 20 ? 20 : [[[app service] getHistoryURIs] count]);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	const NSInteger TITLE_TAG = 1001;
	const NSInteger URI_TAG = 1002;
	
	UILabel *title;
	UILabel *uri;
	
	static NSString *CellIdentifier = @"Cell";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:CellIdentifier] autorelease];
		title = [[[UILabel alloc] initWithFrame:CGRectMake(
														   cell.indentationWidth,
														   tableView.rowHeight - 40,
														   tableView.bounds.size.width - cell.indentationWidth - 10,
														   20)] autorelease];
		[cell.contentView addSubview:title];
		title.tag = TITLE_TAG;
		title.font = [UIFont systemFontOfSize:[UIFont labelFontSize] + 1];
		
		uri = [[[UILabel alloc] initWithFrame:CGRectMake(
														 cell.indentationWidth,
														 tableView.rowHeight - 20,
														 tableView.bounds.size.width - cell.indentationWidth - 10,
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
	if ([[app currentList] isEqualToString:@"Bookmarks"]) {
		title.text = [[[app service] getBookmarkTitles] objectAtIndex:indexPath.row];
		uri.text = [[[app service] getBookmarkURIs] objectAtIndex:indexPath.row];
	} else if ([[app currentList] isEqualToString:@"Tabs"]) {
		title.text = [[[app service] getTabTitles] objectAtIndex:indexPath.row];
		uri.text = [[[app service] getTabURIs] objectAtIndex:indexPath.row];
	} else {
		title.text = [[[app service] getHistoryTitles] objectAtIndex:indexPath.row];
		uri.text = [[[app service] getHistoryURIs] objectAtIndex:indexPath.row];
	}

	return cell;
}

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if ([[app currentList] isEqualToString:@"Bookmarks"]) {
		[app setUri:[[[app service] getBookmarkURIs] objectAtIndex:indexPath.row]];
	} else if ([[app currentList] isEqualToString:@"Tabs"]) {
		[app setUri:[[[app service] getTabURIs] objectAtIndex:indexPath.row]];
	} else {
		[app setUri:[[[app service] getHistoryURIs] objectAtIndex:indexPath.row]];
	}
	[app switchListToWeb];
}

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
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


- (void)dealloc {
    [super dealloc];
}


@end
