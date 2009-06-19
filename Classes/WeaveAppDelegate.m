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
#import "ListController.h"
#import "WebViewController.h"
#import "MainViewController.h"
#import "InfoController.h"
#import "Store.h"

#import <QuartzCore/QuartzCore.h>

@implementation WeaveAppDelegate

@synthesize window, service, uri, currentList;
@synthesize infoController, listController, loginController, webController, mainController;

-(void) applicationDidFinishLaunching:(UIApplication *)application {
	service = [[Service alloc] initWithServer:@"https://services.mozilla.com/proxy/"];
	
	if ([service.store getUsers] == 0) {
		[window addSubview:loginController.view];
	} else {
		[service loadFromStore];
		[service updateDataWithCallback:mainController];
		[window addSubview:mainController.view];
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

-(void) switchFromWeb {
	if (bToList)
		[self switchToView:listController.view From:webController.view withDirection:kCATransitionFromLeft];
	else
		[self switchToView:mainController.view From:webController.view withDirection:kCATransitionFromLeft];
}

-(void) switchMainToWeb {
	bToList = NO;
	[self switchToView:webController.view From:mainController.view withDirection:kCATransitionFromRight];
	
	/* Load URI */
	[webController.webView setScalesPageToFit:YES];
	[webController.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:uri]]];
}

-(void) switchListToWeb {
	bToList = YES;
	[self switchToView:webController.view From:listController.view withDirection:kCATransitionFromRight];
	
	/* Load URI */
	[webController.webView setScalesPageToFit:YES];
	[webController.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:uri]]];	
}

-(void) switchMainToInfo {
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:1.5];
	[UIView setAnimationTransition:UIViewAnimationTransitionFlipFromRight forView:window cache:NO];
	[mainController.view removeFromSuperview];
	[self.window addSubview:infoController.view];
	[UIView commitAnimations];
}

-(void) switchInfoToMain {
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:1.5];
	[UIView setAnimationTransition:UIViewAnimationTransitionFlipFromLeft forView:window cache:NO];
	[infoController.view removeFromSuperview];
	[self.window addSubview:mainController.view];
	[UIView commitAnimations];
}

-(void) switchMainToList {
	[listController.tView reloadData];
	[self switchToView:listController.view From:mainController.view withDirection:kCATransitionFromRight];
}

-(void) switchListToMain:(id)sender {
	[self switchToView:mainController.view From:listController.view withDirection:kCATransitionFromLeft];
}

-(void) switchLoginToMain {
	[service loadDataWithCallback:mainController];
	[self switchToView:mainController.view From:loginController.view withDirection:kCATransitionFromRight];
}

-(void) dealloc {
	[service release];
    [window release];
	[listController release];
	[loginController release];
	[webController release];
	[mainController release];
    [super dealloc];
}

@end
