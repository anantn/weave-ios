//
//  WeaveAppDelegate.m
//  Weave
//
//  Created by Anant Narayanan on 29/03/09.
//  Copyright Anant Narayanan 2009. All rights reserved.
//

#import "Service.h"
#import "WeaveAppDelegate.h"
#import "LoginViewController.h"
#import "TabViewController.h"
#import "Store.h"

@implementation WeaveAppDelegate

@synthesize window, service, tabController, loginController;

-(void) applicationDidFinishLaunching:(UIApplication *)application {
	service = [[Service alloc] initWithServer:@"services.mozilla.com"];
	if ([service.store getUsers] == 0) {
		[window addSubview:loginController.view];
	} else {
		[window addSubview:tabController.view];
	}
	[window makeKeyAndVisible];
}

-(void) flip {
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:2.0];
	[UIView setAnimationTransition:UIViewAnimationTransitionFlipFromRight forView:window cache:NO];
	[loginController.view removeFromSuperview];
	[self.window addSubview:[tabController view]];
	[UIView commitAnimations];
}

-(void) dealloc {
	[service release];
    [window release];
	[tabController release];
	[loginController release];
    [super dealloc];
}

@end
