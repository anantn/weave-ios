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

#import <UIKit/UIKit.h>

@class WeaveAppDelegate;

@interface SearchController : UIViewController <UIAccelerometerDelegate> {
	BOOL searching;
	BOOL okToUpdate;
	
	UISearchBar *searchBar;
	UITableView *tableView;
	
	NSMutableArray *bmkList;
	NSMutableArray *histList;
	
	WeaveAppDelegate *app;
}

@property (nonatomic, retain) WeaveAppDelegate *app;
@property (nonatomic, retain) IBOutlet UISearchBar *searchBar;
@property (nonatomic, retain) IBOutlet UITableView *tableView;

@property (nonatomic, retain) NSMutableArray *bmkList;
@property (nonatomic, retain) NSMutableArray *histList;

- (void)searchTableView;

@end
