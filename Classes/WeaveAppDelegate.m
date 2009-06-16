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

#import <QuartzCore/QuartzCore.h>

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

-(void) switchToView:(UIView *)dst From:(UIView *)src withDirection:(NSString *)direction {
	CATransition *tr = [CATransition animation];
	tr.duration = 0.75;
	tr.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
	
	tr.type = kCATransitionPush;
	tr.subtype = direction;
	
	dst.hidden = YES;
	[self.window addSubview:dst];
	[self.window.layer addAnimation:tr forKey:nil];
	
	src.hidden = YES;
	dst.hidden = NO;
	[src removeFromSuperview];	
}

-(void) switchWebToMain {
	[self switchToView:tabController.view From:webController.view withDirection:kCATransitionFromLeft];
	
	/* WTF? But seems to be needed to get a non-blank view when switching back from webview */
	[tabController setSelectedIndex:1];
	[tabController.searchView reloadData];
	[tabController setSelectedIndex:0];
}

-(void) switchMainToWeb {
	[self switchToView:webController.view From:tabController.view withDirection:kCATransitionFromRight];
	
	/* Load URI */
	[webController.webView setScalesPageToFit:YES];
	[webController.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:uri]]];
}

-(void) switchLoginToMain {
	[self switchToView:tabController.view From:loginController.view withDirection:kCATransitionFromRight];
}

-(void) dealloc {
	[service release];
    [window release];
	[tabController release];
	[loginController release];
    [super dealloc];
}

@end
