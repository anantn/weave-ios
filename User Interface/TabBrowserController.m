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
 Dan Walkowski <dan.walkowski@gmail.com>
 
 ***** END LICENSE BLOCK *****/

#import "TabBrowserController.h"
#import "WebPageController.h"
#import "WeaveAppDelegate.h"
#import "Store.h"

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



- (void)viewDidAppear:(BOOL)animated
{
  UITableView* theTable = (UITableView*)self.view;
	[theTable deselectRowAtIndexPath:[theTable indexPathForSelectedRow] animated: YES];
}

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
    return [[[[Store getStore] getTabs] objectAtIndex:section] objectForKey:@"client"];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return [[[Store getStore] getTabs] count];
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return [[[[[Store getStore] getTabs] objectAtIndex:section] objectForKey:@"tabs"] count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
      
//NOT USING THIS FOR NOW, IB-specified cell.  we can use it later to make them pretty :)
//  UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"tabCell"];
//  if (cell == nil) {
//    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"TabCell" owner:self options:nil];
//    cell = (UITableViewCell *)[nib objectAtIndex:0];
//  }
    
  static NSString *CellIdentifier = @"tabCell";
  
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  if (cell == nil) {
    cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
  }
  
  NSDictionary* tabItem = [[[[[Store getStore] getTabs] objectAtIndex:indexPath.section] objectForKey:@"tabs"] objectAtIndex:indexPath.row];
  
  //FIX need to fill in the other field
//  theIcon = [tabItem objectForKey:@"icon"];
  
  cell.textLabel.text = [tabItem objectForKey:@"title"];
  cell.detailTextLabel.text = [tabItem objectForKey:@"uri"];
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


- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
  UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
  NSURL* destination = [NSURL URLWithString:cell.detailTextLabel.text];
  
  WebPageController* webPage = [[WebPageController alloc] initWithURL:destination];
  WeaveAppDelegate* appDelegate = (WeaveAppDelegate *)[[UIApplication sharedApplication] delegate];
  
  [[appDelegate rootController] presentModalViewController: webPage animated:YES];
  [webPage release];
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/


/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/


/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/


/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


- (void)dealloc {
    [super dealloc];
}


@end

