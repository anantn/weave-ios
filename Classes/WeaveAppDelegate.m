/***** BEGIN LICENSE BLOCK *****
 Version: MPL 1.1
 
 The contents of this file are subject to the Mozilla Public License Version 
 1.1 (the "License"); you may not use this file except in compliance with 
 the License. You may obtain a copy of the License at 
 http://www.mozilla.org/MPL/
 
 Software distributed under the License is distributed on an "AS IS" basis,
 WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 for the specific language governing rights and limitations under the
 License.
 
 The Original Code is weave-iphone.
 
 The Initial Developer of the Original Code is Mozilla Labs.
 Portions created by the Initial Developer are Copyright (C) 2009
 the Initial Developer. All Rights Reserved.
 
 Contributor(s):
	Anant Narayanan <anant@kix.in>
 
 ***** END LICENSE BLOCK *****/

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
	service = [[Service alloc] initWithServer:@"https://services.mozilla.com/proxy2/"];
	
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
	tr.duration = 0.4;
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
