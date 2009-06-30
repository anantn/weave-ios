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
 
 ***** END LICENSE BLOCK *****/

#import "SearchController.h"
#import "WeaveAppDelegate.h"
#import "Service.h"
#import "Store.h"
#import "Utility.h"
#import <QuartzCore/QuartzCore.h>

@implementation SearchController

@synthesize searchBar, tableView;
@synthesize bmkList, histList, app;

- (void)viewDidLoad {
    [super viewDidLoad];
	app = (WeaveAppDelegate *)[[UIApplication sharedApplication] delegate];
	bmkList = [[NSMutableArray alloc] init];
	histList = [[NSMutableArray alloc] init];
	[searchBar setShowsCancelButton:YES animated:YES];
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
					cell.indentationWidth + 24,
					tv.rowHeight - 40,
					tv.bounds.size.width - cell.indentationWidth - star.size.width - 34,
					20)] autorelease];
		[cell.contentView addSubview:title];
		title.tag = TITLE_TAG;
		title.font = [UIFont systemFontOfSize:[UIFont labelFontSize] + 1];
		
		uri = [[[UILabel alloc] initWithFrame:CGRectMake(
					cell.indentationWidth + 24,
					tv.rowHeight - 20,
					tv.bounds.size.width - cell.indentationWidth - star.size.width - 34,
					18)] autorelease];
		[cell.contentView addSubview:uri];
		uri.tag = URI_TAG;
		uri.font = [UIFont systemFontOfSize:[UIFont labelFontSize] - 3];
		uri.textColor = [UIColor colorWithRed:0.34 green:0.50 blue:0.77 alpha:1.0];
	} else {
		title = (UILabel *)[cell viewWithTag:TITLE_TAG];
		uri = (UILabel *)[cell viewWithTag:URI_TAG];
	}
	
	cell.image = nil;
	cell.accessoryView = nil;
	if (searching) {
		NSArray *obj;
		if (indexPath.row >= [bmkList count]) {
			obj = [histList objectAtIndex:(indexPath.row - [bmkList count])];
			title.text = [obj objectAtIndex:0];
			uri.text = [obj objectAtIndex:1];
		} else {
			obj = [bmkList objectAtIndex:indexPath.row];
			title.text = [obj objectAtIndex:0];
			uri.text = [obj objectAtIndex:1];
			cell.accessoryView = [[[UIImageView alloc] initWithImage:star] autorelease];
		}
		
		NSDictionary *icons = [[app service] getIcons];
		cell.image = [UIImage imageWithData:[[[NSData alloc] initWithBase64EncodedString:[icons objectForKey:[obj objectAtIndex:2]]] autorelease]];
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

- (void)searchBarTextDidBeginEditing:(UISearchBar *)theSearchBar {
	searching = YES;
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)theSearchBar {
	searching = NO;
	searchBar.text = @"";
	[searchBar resignFirstResponder];
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
	searching = YES;
	[searchBar resignFirstResponder];
	[tableView reloadData];
}

- (void)searchTableView {
	int i;
	NSString *searchText = searchBar.text;
	[bmkList removeAllObjects];
	[histList removeAllObjects];
	
	NSArray *bmT = [[app service] getBookmarks];
	NSArray *hiT = [[app service] getHistory];
	
	/* Bookmark search */
	for (i = 0; i < [bmT count]; i++) {
		NSString *uri = [[bmT objectAtIndex:i] objectAtIndex:0];
		NSString *title = [[bmT objectAtIndex:i] objectAtIndex:1];
		
		NSRange ru = [uri rangeOfString:searchText options:NSCaseInsensitiveSearch];
		NSRange rt = [title rangeOfString:searchText options:NSCaseInsensitiveSearch];
		
		if (ru.length > 0 || rt.length > 0)
			[bmkList addObject:[NSArray arrayWithObjects:title, uri, [[bmT objectAtIndex:i] objectAtIndex:2], nil]];
	}
	
	/* History search */
	for (i = 0; i < [hiT count]; i++) {
		NSString *uri = [[hiT objectAtIndex:i] objectAtIndex:0];
		NSString *title = [[hiT objectAtIndex:i] objectAtIndex:1];
		
		NSRange hu = [uri rangeOfString:searchText options:NSCaseInsensitiveSearch];
		NSRange ht = [title rangeOfString:searchText options:NSCaseInsensitiveSearch];
		
		if (hu.length > 0 || ht.length > 0)
			[histList addObject:[NSArray arrayWithObjects:title, uri, [[hiT objectAtIndex:i] objectAtIndex:2], nil]];
	}
}

- (void)dealloc {
    [super dealloc];
}


@end
