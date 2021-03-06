/***** BEGIN LICENSE BLOCK *****
 Version: MPL 1.1/GPL 2.0/LGPL 2.1
 
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

 Alternatively, the contents of this file may be used under the terms of either
 the GNU General Public License Version 2 or later (the "GPL"), or the GNU
 Lesser General Public License Version 2.1 or later (the "LGPL"), in which case
 the provisions of the GPL or the LGPL are applicable instead of those above.
 If you wish to allow use of your version of this file only under the terms of
 either the GPL or the LGPL, and not to allow others to use your version of
 this file under the terms of the MPL, indicate your decision by deleting the
 provisions above and replace them with the notice and other provisions
 required by the GPL or the LGPL. If you do not delete the provisions above, a
 recipient may use your version of this file under the terms of any one of the
 MPL, the GPL or the LGPL.
 
 ***** END LICENSE BLOCK *****/

#import "TabBrowserController.h"
#import "WebPageController.h"
#import "Store.h"
#import "TapActionController.h"

@implementation TabBrowserController

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

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [[retainedTabs objectAtIndex:section] objectForKey:@"client"];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
  [retainedTabs release];
  retainedTabs = [[[Store getStore] getTabs] retain];
  [retainedFavicons release];
  retainedFavicons = [[[Store getStore] getFavicons] retain];

  return [retainedTabs count];
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return [[[retainedTabs objectAtIndex:section] objectForKey:@"tabs"] count];
}


//Note: this table cell code is nearly identical to the same method in searchresults and bookmarks,
// but we want to be able to easily make them display differently, so it is replicated
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString *CellIdentifier = @"tabCell";
  
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  if (cell == nil) {
    cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
  }
  
  NSDictionary* tabItem = [[[retainedTabs objectAtIndex:indexPath.section] objectForKey:@"tabs"] objectAtIndex:indexPath.row];
    
  cell.textLabel.adjustsFontSizeToFitWidth = YES;
  cell.textLabel.minimumFontSize = 13;
  cell.textLabel.text = [tabItem objectForKey:@"title"];
  cell.detailTextLabel.text = [tabItem objectForKey:@"uri"];

  //set it to the default to start
  cell.imageView.image = [retainedFavicons objectForKey:@"blankfavicon.ico"];
  NSString* iconPath = [tabItem objectForKey:@"icon"];
  
  if (iconPath != nil && [iconPath length] > 0)
  {
    UIImage* favicon = [retainedFavicons objectForKey:iconPath];
    if (favicon != nil) 
    {
      cell.imageView.contentMode = UIViewContentModeScaleAspectFit;
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
	[tap release];
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
}



- (void)dealloc {
    [super dealloc];
}


@end

