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

#import "TabViewController.h"
#import "WeaveAppDelegate.h"
#import "Stockboy.h"

@implementation TabViewController

@synthesize overlay, pgText, pgStatus, pgBar, tView;

- (void)viewDidLoad {
    [super viewDidLoad];
	[self setDelegate:self];

	okToUpdate = NO;
	UIAccelerometer *accel = [UIAccelerometer sharedAccelerometer];
	accel.delegate = self;
	accel.updateInterval = 1.0f/10.0f;
}

- (void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration {
	if (fabsf(acceleration.x) > 1.6 ||
		fabsf(acceleration.y) > 1.6 ||
		fabsf(acceleration.z) > 1.6) {
		if (okToUpdate) 
    {
			okToUpdate = NO;
			[[Stockboy getStockboy] refreshStock];
		}
	}
}

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
	[tView reloadData];
}

- (void)downloadComplete:(BOOL)success {
	overlay.hidden = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}


@end
