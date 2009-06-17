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
@class ListController;
@class WebViewController;
@class MainViewController;
@class LoginViewController;

@interface WeaveAppDelegate : NSObject <UIApplicationDelegate> {
	NSString *uri;
	NSString *currentList;
	
	UIWindow *window;
	
	Service *service;
	ListController *listController;
	WebViewController *webController;
	MainViewController *mainController;
	LoginViewController *loginController;
}

@property (retain) Service *service;
@property (nonatomic, copy) NSString *uri;
@property (nonatomic, copy) NSString *currentList;
@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet ListController *listController;
@property (nonatomic, retain) IBOutlet WebViewController *webController;
@property (nonatomic, retain) IBOutlet MainViewController *mainController;
@property (nonatomic, retain) IBOutlet LoginViewController *loginController;

-(void) switchMainToWeb;
-(void) switchWebToMain;
-(void) switchMainToList;
-(void) switchLoginToMain;

-(IBAction) switchListToMain:(id)sender;

@end
