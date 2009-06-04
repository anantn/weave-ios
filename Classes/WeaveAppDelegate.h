//
//  WeaveAppDelegate.h
//  Weave
//
//  Created by Anant Narayanan on 29/03/09.
//  Copyright Anant Narayanan 2009. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Service;
@class LoginViewController;

@interface WeaveAppDelegate : NSObject <UIApplicationDelegate> {
	UIWindow *window;
	Service *service;
	UITabBarController *tabBarController;
}

@property (retain) Service *service;
@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UITabBarController *tabBarController;

@end
