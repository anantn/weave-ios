//
//  TabController.h
//  Weave
//
//  Created by Anant Narayanan on 6/16/09.
//  Copyright 2009 Mozilla Corporation. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WeaveAppDelegate;
@class TabViewController;

@interface ListController : UITableViewController {
	UITableView *tView;
	WeaveAppDelegate *app;
	TabViewController *tabController;
}

@property (nonatomic, retain) IBOutlet UITableView *tView;
@property (nonatomic, retain) IBOutlet TabViewController *tabController;

@end
