//
//  RecentController.m
//  Weave
//
//  Created by Anant Narayanan on 6/16/09.
//  Copyright 2009 Mozilla Corporation. All rights reserved.
//

#import "ListController.h"
#import "WeaveAppDelegate.h"
#import "TabViewController.h"
#import "Service.h"

@implementation ListController

@synthesize tView, tabController;

- (void)viewDidLoad {
    [super viewDidLoad];
	app = (WeaveAppDelegate *)[[UIApplication sharedApplication] delegate];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {    
	return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if (tabController.selectedIndex == 2)
		return @"Bookmarks";
	else if (tabController.selectedIndex == 1)
		return @"Tabs";
	else
		return @"History";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (tabController.selectedIndex == 2)
		return [[[app service] getBookmarkURIs] count];
	else if (tabController.selectedIndex == 1)
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
	if (tabController.selectedIndex == 2) {
		title.text = [[[app service] getBookmarkTitles] objectAtIndex:indexPath.row];
		uri.text = [[[app service] getBookmarkURIs] objectAtIndex:indexPath.row];
	} else if (tabController.selectedIndex == 1) {
		title.text = [[[app service] getTabTitles] objectAtIndex:indexPath.row];
		uri.text = [[[app service] getTabURIs] objectAtIndex:indexPath.row];
	} else {
		title.text = [[[app service] getHistoryTitles] objectAtIndex:indexPath.row];
		uri.text = [[[app service] getHistoryURIs] objectAtIndex:indexPath.row];
	}

	return cell;
}

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (tabController.selectedIndex == 2) {
		[app setUri:[[[app service] getBookmarkURIs] objectAtIndex:indexPath.row]];
	} else if (tabController.selectedIndex == 1) {
		[app setUri:[[[app service] getTabURIs] objectAtIndex:indexPath.row]];
	} else {
		[app setUri:[[[app service] getHistoryURIs] objectAtIndex:indexPath.row]];
	}
	[app switchMainToWeb];
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
