//
//  MainViewController.h
//  Weave
//
//  Created by Anant Narayanan on 6/16/09.
//  Copyright 2009 Mozilla Corporation. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface MainViewController : UIViewController {
	UILabel *awTitle;
	UILabel *pgTitle;
	UIButton *bmkButton;
	UIButton *tabButton;
	UISearchBar *search;
	UIProgressView *pgBar;
	UIActivityIndicatorView *spinner;
}

@property (nonatomic, retain) IBOutlet UILabel *awTitle;
@property (nonatomic, retain) IBOutlet UILabel *pgTitle;
@property (nonatomic, retain) IBOutlet UIButton *bmkButton;
@property (nonatomic, retain) IBOutlet UIButton *tabButton;
@property (nonatomic, retain) IBOutlet UISearchBar *search;
@property (nonatomic, retain) IBOutlet UIProgressView *pgBar;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *spinner;

@end
