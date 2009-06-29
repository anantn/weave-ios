//
//  SearchController.h
//  Weave
//
//  Created by Anant Narayanan on 6/16/09.
//  Copyright 2009 Mozilla Corporation. All rights reserved.
//

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
