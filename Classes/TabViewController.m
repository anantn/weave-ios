//
//  TabViewController.m
//  Weave
//
//  Created by Anant Narayanan on 6/24/09.
//  Copyright 2009 Mozilla Corporation. All rights reserved.
//

#import "TabViewController.h"
#import "WeaveAppDelegate.h"
#import "Service.h"

@implementation TabViewController

@synthesize overlay, pgText, pgStatus, pgBar, tView;

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	[self setDelegate:self];

	okToUpdate = NO;
	UIAccelerometer *accel = [UIAccelerometer sharedAccelerometer];
	accel.delegate = self;
	accel.updateInterval = 1.0f/10.0f;
}

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration {
	if (fabsf(acceleration.x) > 1.6 ||
		fabsf(acceleration.y) > 1.6 ||
		fabsf(acceleration.z) > 1.6) {
		if (okToUpdate) {
			okToUpdate = NO;
			[[(WeaveAppDelegate *)[[UIApplication sharedApplication] delegate] service] updateDataWithCallback:self];
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
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}


@end
