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

#import "ListController.h"
#import "WeaveAppDelegate.h"
#import "TabViewController.h"
#import "Store.h"
#import "Utility.h"

@implementation ListController

@synthesize tView, tabController;


#define SEARCH_VIEW 0
#define TAB_VIEW 1
#define HISTORY_VIEW 2


- (void)viewDidLoad {
    [super viewDidLoad];
	app = (WeaveAppDelegate *)[[UIApplication sharedApplication] delegate];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {    
	if (tabController.selectedIndex == TAB_VIEW) {
		return [[[Store getStore] getTabIndex] count];
	} else {
		return 1;
	}
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if (tabController.selectedIndex == TAB_VIEW) {
		return [[[Store getStore] getTabIndex] objectAtIndex:section];
	} else {
		return @"History";
	}
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
	if (tabController.selectedIndex == HISTORY_VIEW) 
  {
		return ([[[Store getStore] getHistory] count] > 20 ? 20 : [[[Store getStore] getHistory] count]);
	} 
  else
  {    
    NSArray *tabIndex = [[Store getStore] getTabIndex];
    NSDictionary *tabs = [[Store getStore] getTabs];
    if (![tabIndex count]) return 0;  //empty tab list

    return [[tabs objectForKey:[tabIndex objectAtIndex:section]] count];
  }
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
					cell.indentationWidth + 30,
					tableView.rowHeight - 40,
					tableView.bounds.size.width - cell.indentationWidth - 30,
					20)] autorelease];
		[cell.contentView addSubview:title];
		title.tag = TITLE_TAG;
		title.font = [UIFont systemFontOfSize:[UIFont labelFontSize] + 1];
		
		uri = [[[UILabel alloc] initWithFrame:CGRectMake(
            cell.indentationWidth + 30,
			tableView.rowHeight - 20,
			tableView.bounds.size.width - cell.indentationWidth - 30,
			18)] autorelease];
		[cell.contentView addSubview:uri];
		uri.tag = URI_TAG;
		uri.font = [UIFont systemFontOfSize:[UIFont labelFontSize] - 3];
		uri.textColor = [UIColor colorWithRed:0.34 green:0.50 blue:0.77 alpha:1.0];
	} else {
		title = (UILabel *)[cell viewWithTag:TITLE_TAG];
		uri = (UILabel *)[cell viewWithTag:URI_TAG];
	}
	
	cell.imageView.image = nil;
	cell.accessoryView = nil;

	NSArray *obj;
	if (tabController.selectedIndex == TAB_VIEW) 
  {
		NSDictionary *tabs = [[Store getStore] getTabs];
    NSArray* tabIndex = [[Store getStore] getTabIndex];
    
		obj = [[tabs objectForKey:[tabIndex objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row];
    
		title.text = [obj objectAtIndex:1];
		uri.text = [obj objectAtIndex:0];
	}
  else 
  {
		obj = [[[Store getStore] getHistory] objectAtIndex:indexPath.row];
		title.text = [obj objectAtIndex:1];
		uri.text = [obj objectAtIndex:0];
	}

	NSDictionary *icons = [[Store getStore] getFavicons];
	if ([icons objectForKey:[obj objectAtIndex:2]] != nil) {
		cell.imageView.image = [UIImage imageWithData:[[[NSData alloc]
								initWithBase64EncodedString:[icons objectForKey:[obj objectAtIndex:2]]] autorelease]];
	} else {
		cell.imageView.image = [UIImage imageNamed:@"Document.png"];
	}
	
	return cell;
}

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (tabController.selectedIndex == TAB_VIEW) {
		NSDictionary *tabs = [[Store getStore] getTabs];
    NSArray* tabIndex = [[Store getStore] getTabIndex];

		NSArray *obj = [[tabs objectForKey:[tabIndex objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row];
    
		[app setUri:[obj objectAtIndex:0]];
	} else {
		[app setUri:[[[[Store getStore] getHistory] objectAtIndex:indexPath.row] objectAtIndex:0]];
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
