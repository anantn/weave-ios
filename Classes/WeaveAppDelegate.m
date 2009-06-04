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

@synthesize window, service;

-(void) applicationDidFinishLaunching:(UIApplication *)application {
	service = [[Service alloc] initWithServer:@"auth.services.mozilla.com"];
	// Override point for customization after app launch
	//[window addSubview:loginController.view];
	[window makeKeyAndVisible];
}


-(void) dealloc {
	[service release];
    [window release];
    [super dealloc];
}


@end
