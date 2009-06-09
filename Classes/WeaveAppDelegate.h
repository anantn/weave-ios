//
//  WeaveAppDelegate.h
//  Weave
//
//  Created by Anant Narayanan on 29/03/09.
//  Copyright Anant Narayanan 2009. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Store;
@class Service;
@class TabViewController;
@class LoginViewController;

@interface WeaveAppDelegate : NSObject <UIApplicationDelegate> {
	UIWindow *window;
	Service *service;
	TabViewController *tabController;
	LoginViewController *loginController;
}

@property (retain) Service *service;
@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet TabViewController *tabController;
@property (nonatomic, retain) IBOutlet LoginViewController *loginController;

-(void) flip;

@end
