//
//  BookmarkBrowserController.m
//  Weave
//
//  Created by Dan Walkowski on 11/19/09.
//  Copyright 2009 ClownWare. All rights reserved.
//

#import "BookmarkBrowserController.h"
#import "Store.h"

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

/*
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}
*/
- (void)viewDidAppear:(BOOL)animated
{
  UITableView* theTable = (UITableView*)self.view;
	[theTable deselectRowAtIndexPath:[theTable indexPathForSelectedRow] animated: YES];
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
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return [[[Store getStore] getBookmarks] count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"bookmarkCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
    }
    
  NSArray* bookmarkItem = [[[Store getStore] getBookmarks] objectAtIndex:indexPath.row];
  
  cell.textLabel.text = [bookmarkItem objectAtIndex:1];
  cell.detailTextLabel.text = [bookmarkItem objectAtIndex:0];
  cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
  
  //this should really be the icon from the db
  //  theIcon = [tabItem objectForKey:@"icon"];
  cell.imageView.image = [UIImage imageNamed:@"Star.png"];

  return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
  UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
  [[UIApplication sharedApplication] openURL:[NSURL URLWithString:cell.detailTextLabel.text]];
}




- (void)dealloc {
    [super dealloc];
}


@end

