//
//  MainViewController.m
//  Weave
//
//  Created by Anant Narayanan on 6/16/09.
//  Copyright 2009 Mozilla Corporation. All rights reserved.
//

#import "MainViewController.h"
#import "WeaveAppDelegate.h"
#import "Service.h"
#import "Store.h"
#import <QuartzCore/QuartzCore.h>

@implementation MainViewController

@synthesize bmkList, histList, app;
@synthesize pgTitle, pgBar, searchBar;
@synthesize subView, iconView, tableView;
@synthesize bmkButton, tabButton, spinner;

- (void)viewDidLoad {
    [super viewDidLoad];
	app = (WeaveAppDelegate *)[[UIApplication sharedApplication] delegate];
	
	pgBar.hidden = YES;
	pgTitle.hidden = YES;
	spinner.hidden = YES;
	
	if ([[app service].store getUsers] > 0) {
		[[app service] loadFromStore];
	}
	
	[subView addSubview:iconView];
}

- (void)getOrUpdate:(id)sender {
	[[app service] loadDataWithCallback:self];
}

- (void)downloadComplete:(BOOL)success {
	NSDateFormatter *dF = [[NSDateFormatter alloc] init];
	[dF setDateStyle:NSDateFormatterShortStyle];
	[dF	setTimeStyle:NSDateFormatterShortStyle];
	
	[pgTitle setText:[dF stringFromDate:[NSDate date]]];
	[dF release];
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}

/* Table View */
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {    
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (searching)
		return [bmkList count] + [histList count];
	else
		return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if (searching)
		return @"Search Results";
	else
		return @"";
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	const NSInteger TITLE_TAG = 1001;
	const NSInteger URI_TAG = 1002;
	
	UILabel *title;
	UILabel *uri;
	UIImage *star = [UIImage imageNamed:@"Star.png"];
	
	static NSString *CellIdentifier = @"Cell";
	UITableViewCell *cell = [tv dequeueReusableCellWithIdentifier:CellIdentifier];
	
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:CellIdentifier] autorelease];
		title = [[[UILabel alloc] initWithFrame:CGRectMake(
					cell.indentationWidth,
					tv.rowHeight - 40,
					tv.bounds.size.width - cell.indentationWidth - star.size.width - 10,
					20)] autorelease];
		[cell.contentView addSubview:title];
		title.tag = TITLE_TAG;
		title.font = [UIFont systemFontOfSize:[UIFont labelFontSize] + 1];
		
		uri = [[[UILabel alloc] initWithFrame:CGRectMake(
					cell.indentationWidth,
					tv.rowHeight - 20,
					tv.bounds.size.width - cell.indentationWidth - star.size.width - 10,
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
	if (searching) {
		if (indexPath.row >= [bmkList count]) {
			title.text = [[histList objectAtIndex:(indexPath.row - [bmkList count])] objectAtIndex:0];
			uri.text = [[histList objectAtIndex:(indexPath.row - [bmkList count])] objectAtIndex:1];
		} else {
			title.text = [[bmkList objectAtIndex:indexPath.row] objectAtIndex:0];
			uri.text = [[bmkList objectAtIndex:indexPath.row] objectAtIndex:1];
			cell.accessoryView = [[[UIImageView alloc] initWithImage:star] autorelease];
		}
	}
	
	return cell;
}

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (searching) {
		if (indexPath.row >= [bmkList count]) {
			[app setUri:[[histList objectAtIndex:(indexPath.row - [bmkList count])] objectAtIndex:1]];
		} else {
			[app setUri:[[bmkList objectAtIndex:indexPath.row] objectAtIndex:1]];
		}
		
		[app switchMainToWeb];
	}
}

- (void)tableView:(UITableView *)tv accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {	
	[self tableView:tv didSelectRowAtIndexPath:indexPath];
}

/* Search bar */
- (void)searchBarTextDidBeginEditing:(UISearchBar *)theSearchBar {
	searching = YES;
	
	CATransition *tr = [CATransition animation];
	tr.duration = 1.0;
	tr.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
	tr.type = kCATransitionPush;
	tr.subtype = kCATransitionFromBottom;
	
	tableView.hidden = YES;
	[subView addSubview:tableView];
	[subView.layer addAnimation:tr forKey:nil];
	
	iconView.hidden = YES;
	tableView.hidden = NO;
	[iconView removeFromSuperview];
	
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
	
	[tableView reloadData];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)theSearchBar {
	searching = NO;
	searchBar.text = @"";
	[searchBar resignFirstResponder];
	[tableView reloadData];
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

- (void)dealloc {
    [super dealloc];
}


@end