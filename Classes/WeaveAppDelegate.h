//
//  WeaveAppDelegate.h
//  Weave
//
//  Created by Anant Narayanan on 29/03/09.
//  Copyright Anant Narayanan 2009. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WeaveService;
@class WeaveLoginViewController;

@interface WeaveAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
	WeaveService *service;
    WeaveLoginViewController *loginController;
}

@property (retain) WeaveService *service;
@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet WeaveLoginViewController *loginController;

@end
