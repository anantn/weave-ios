//
//  BookmarksController.h
//  Weave
//
//  Created by Anant Narayanan on 6/11/09.
//  Copyright 2009 Mozilla Corporation. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WeaveAppDelegate;

@interface BookmarksController : UITableViewController {
	NSMutableArray *list;
	IBOutlet UISearchBar *searchBar;
	BOOL searching;
	BOOL letUserSelectRow;
	WeaveAppDelegate *app;
}

- (void)searchTableView;

@end
