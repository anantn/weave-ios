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
#import "WebViewController.h"
#import "Store.h"

@implementation WeaveAppDelegate

@synthesize window, service, uri;
@synthesize tabController, loginController, webController;

-(void) applicationDidFinishLaunching:(UIApplication *)application {
	service = [[Service alloc] initWithServer:@"services.mozilla.com"];
	if ([service.store getUsers] == 0) {
		[window addSubview:loginController.view];
	} else {
		[window addSubview:tabController.view];
	}
	[window makeKeyAndVisible];
}

-(void) flipToWebFrom:(UIView *)view {
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:1.0];
	[UIView setAnimationTransition:UIViewAnimationTransitionFlipFromLeft forView:window cache:NO];
	[view removeFromSuperview];
	[self.window addSubview:[webController view]];
	[UIView commitAnimations];
	
	[webController.webView setScalesPageToFit:YES];
	[webController.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:uri]]];
}

-(void) flipToListFrom:(UIView *)view {
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:2.0];
	[UIView setAnimationTransition:UIViewAnimationTransitionFlipFromRight forView:window cache:NO];
	[view removeFromSuperview];
	[self.window addSubview:[tabController view]];
	[UIView commitAnimations];

	/* WTF? But seems to be needed to get a non-blank view when switching back from webview */
	[tabController setSelectedIndex:1];
	[tabController.searchView reloadData];
	[tabController setSelectedIndex:0];
}

-(void) dealloc {
	[service release];
    [window release];
	[tabController release];
	[loginController release];
    [super dealloc];
}

@end
