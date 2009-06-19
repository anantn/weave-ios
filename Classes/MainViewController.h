//
//  MainViewController.h
//  Weave
//
//  Created by Anant Narayanan on 6/16/09.
//  Copyright 2009 Mozilla Corporation. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WeaveAppDelegate;

@interface MainViewController : UIViewController <UIAccelerometerDelegate> {
	UILabel *pgTitle;
	UIButton *bmkButton;
	UIButton *tabButton;
	UIProgressView *pgBar;
	UISearchBar *searchBar;
	
	UIActivityIndicatorView *spinner;
	
	BOOL searching;
	BOOL okToUpdate;
	WeaveAppDelegate *app;
	
	UIView *subView;
	UIView *iconView;
	UITableView *tableView;
	
	
	NSMutableArray *bmkList;
	NSMutableArray *histList;
}

@property (nonatomic, retain) IBOutlet UILabel *pgTitle;
@property (nonatomic, retain) IBOutlet UIButton *bmkButton;
@property (nonatomic, retain) IBOutlet UIButton *tabButton;
@property (nonatomic, retain) IBOutlet UIProgressView *pgBar;
@property (nonatomic, retain) IBOutlet UISearchBar *searchBar;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *spinner;

@property (nonatomic, retain) IBOutlet UIView *subView;
@property (nonatomic, retain) IBOutlet UIView *iconView;
@property (nonatomic, retain) IBOutlet UITableView *tableView;

@property (nonatomic, retain) WeaveAppDelegate *app;
@property (nonatomic, retain) NSMutableArray *bmkList;
@property (nonatomic, retain) NSMutableArray *histList;

- (IBAction)gotoInfoPage:(id)sender;
- (IBAction)gotoTabsList:(id)sender;
- (IBAction)gotoHistoryList:(id)sender;
- (IBAction)gotoBookmarkList:(id)sender;

- (void)downloadComplete:(BOOL)success;
- (void)searchTableView;

@end
