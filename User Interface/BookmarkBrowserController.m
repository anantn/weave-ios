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
 Dan Walkowski <dan.walkowski@mozilla.com>
 
 ***** END LICENSE BLOCK *****/

#import "BookmarkBrowserController.h"
#import "WebPageController.h"
#import "Store.h"
#import "TapActionController.h"

@implementation BookmarkBrowserController

/*
- (id)initWithStyle:(UITableViewStyle)style {
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    if (self = [super initWithStyle:style]) {
    }
    return self;
}
*/

/*
- (void)viewDidLoad {
    [super viewDidLoad];

    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}
*/


//- (void)viewWillAppear:(BOOL)animated {
//    [super viewWillAppear:animated];
//}

//- (void)viewDidAppear:(BOOL)animated
//{
//}

- (void) refresh
{ 
  UITableView* theTable = (UITableView*)self.view;
  [theTable reloadData];
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


#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
  //temporary caching, until we are done redrawing our table. 
  // no copying, just bumping the refcount

  [retainedBookmarks release];
  retainedBookmarks = [[[Store getStore] getBookmarks] retain];
  [retainedFavicons release];
  retainedFavicons = [[[Store getStore] getFavicons] retain];

  return [retainedBookmarks count];
}


//Note: this table cell code is nearly identical to the same method in searchresults and tabs,
// but we want to be able to easily make them display differently, so it is replicated
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"bookmarkCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
    }
    
  NSDictionary* bookmarkItem = [retainedBookmarks objectAtIndex:indexPath.row];
  
  cell.textLabel.adjustsFontSizeToFitWidth = YES;
  cell.textLabel.minimumFontSize = 13;
  cell.textLabel.text = [bookmarkItem objectForKey:@"title"];
  cell.detailTextLabel.text = [bookmarkItem objectForKey:@"uri"];
  
  //set it to the default to start
  cell.imageView.image = [retainedFavicons objectForKey:@"blankfavicon.ico"];
  NSString* iconPath = [bookmarkItem objectForKey:@"icon"];
  
  if (iconPath != nil && [iconPath length] > 0)
  {
    UIImage* favicon = [retainedFavicons objectForKey:iconPath];
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
  TapActionController* tap = [[[TapActionController alloc] initWithDescription:cell.textLabel.text andLocation:cell.detailTextLabel.text] autorelease];
  [tap chooseAction];
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
}


- (void)dealloc {
    [super dealloc];
}


@end

