//
//  TabViewController.h
//  Weave
//
//  Created by Anant Narayanan on 6/24/09.
//  Copyright 2009 Mozilla Corporation. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface TabViewController : UITabBarController <UITabBarControllerDelegate, UIAccelerometerDelegate> {
	UIView *overlay;
	UILabel *pgText;
	UILabel *pgStatus;
	UITableView *tView;
	UIProgressView *pgBar;
	
	BOOL okToUpdate;
}

@property (nonatomic, retain) IBOutlet UIView *overlay;
@property (nonatomic, retain) IBOutlet UILabel *pgText;
@property (nonatomic, retain) IBOutlet UILabel *pgStatus;
@property (nonatomic, retain) IBOutlet UITableView *tView;
@property (nonatomic, retain) IBOutlet UIProgressView *pgBar;

- (void)downloadComplete:(BOOL)success;
- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController;

@end
