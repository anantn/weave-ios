//
//  FirstViewController.h
//  Weave
//
//  Created by Anant Narayanan on 6/4/09.
//  Copyright Mozilla Corporation 2009. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WeaveAppDelegate;

@interface TabViewController : UITabBarController {
	WeaveAppDelegate *app;
	UITableView *searchView;
}

@property (nonatomic, retain) IBOutlet UITableView *searchView;

@end
