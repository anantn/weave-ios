//
//  SearchController.h
//  Weave
//
//  Created by Anant Narayanan on 6/11/09.
//  Copyright 2009 Mozilla Corporation. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WeaveAppDelegate;

@interface SearchController : UITableViewController {
	NSMutableArray *bmkList;
	NSMutableArray *histList;
	IBOutlet UISearchBar *searchBar;
	BOOL searching;
	WeaveAppDelegate *app;
}

- (void)searchTableView;

@end
