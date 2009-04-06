//
//  WeaveAppDelegate.m
//  Weave
//
//  Created by Anant Narayanan on 29/03/09.
//  Copyright Anant Narayanan 2009. All rights reserved.
//

#import "WeaveService.h"
#import "WeaveAppDelegate.h"
#import "WeaveLoginViewController.h"

@implementation WeaveAppDelegate

@synthesize window, service, loginController;

-(void) applicationDidFinishLaunching:(UIApplication *)application {
	service = [[WeaveService alloc] initWithServer:@"auth.services.mozilla.com"];
	// Override point for customization after app launch
	[window addSubview:loginController.view];
	[window makeKeyAndVisible];
}


-(void) dealloc {
	[service release];
    [loginController release];
    [window release];
    [super dealloc];
}


@end
