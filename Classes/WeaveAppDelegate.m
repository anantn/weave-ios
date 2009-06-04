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

@implementation WeaveAppDelegate

@synthesize window, service, tabBarController;

-(void) applicationDidFinishLaunching:(UIApplication *)application {
	service = [[Service alloc] initWithServer:@"auth.services.mozilla.com"];
	
	if ([service isFirstRun]) {
		
	}

	// Override point for customization after app launch
	[window addSubview:tabBarController.view];
	//[window makeKeyAndVisible];
}

/*
 // Optional UITabBarControllerDelegate method
 - (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
 }
 */

/*
 // Optional UITabBarControllerDelegate method
 - (void)tabBarController:(UITabBarController *)tabBarController didEndCustomizingViewControllers:(NSArray *)viewControllers changed:(BOOL)changed {
 }
 */

-(void) dealloc {
	[service release];
    [window release];
    [super dealloc];
}


@end
