//
//  WeaveAppDelegate.m
//  Weave
//
//  Created by Anant Narayanan on 29/03/09.
//  Copyright Anant Narayanan 2009. All rights reserved.
//

#import "Store.h"
#import "Service.h"
#import "WeaveAppDelegate.h"
#import "WebViewController.h"
#import "TabViewController.h"
#import "LoginViewController.h"

#import <QuartzCore/QuartzCore.h>

@implementation WeaveAppDelegate

@synthesize window, service, uri;
@synthesize tabController, loginController, webController;

-(void) applicationDidFinishLaunching:(UIApplication *)application {
	service = [[Service alloc] initWithServer:@"https://services.mozilla.com/proxy/"];
	
	if ([service.store getUsers] == 0) {
		[window addSubview:loginController.view];
	} else {
		[service loadFromStore];
		[service updateDataWithCallback:tabController];
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
}

-(void) switchMainToWeb {
	[self switchToView:webController.view From:tabController.view withDirection:kCATransitionFromRight];
	[webController loadURI:uri];
}

-(void) switchLoginToMain {
	[service loadDataWithCallback:tabController];
	[self switchToView:tabController.view From:loginController.view withDirection:kCATransitionFromRight];
}

-(void) dealloc {
	[window release];
	[service release];
	[tabController release];
	[webController release];
	[loginController release];
	[super dealloc];
}

@end
