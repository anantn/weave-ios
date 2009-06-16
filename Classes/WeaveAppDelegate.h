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
@class WebViewController;
@class LoginViewController;

@interface WeaveAppDelegate : NSObject <UIApplicationDelegate> {
	NSString *uri;
	UIWindow *window;
	
	Service *service;
	TabViewController *tabController;
	WebViewController *webController;
	LoginViewController *loginController;
}

@property (retain) Service *service;
@property (nonatomic, copy) NSString *uri;
@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet TabViewController *tabController;
@property (nonatomic, retain) IBOutlet WebViewController *webController;
@property (nonatomic, retain) IBOutlet LoginViewController *loginController;

-(void) switchMainToWeb;
-(void) switchWebToMain;
-(void) switchLoginToMain;

@end
