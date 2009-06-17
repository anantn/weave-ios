//
//  MainViewController.m
//  Weave
//
//  Created by Anant Narayanan on 6/16/09.
//  Copyright 2009 Mozilla Corporation. All rights reserved.
//

#import "MainViewController.h"
#import "WeaveAppDelegate.h"
#import "Service.h"

@implementation MainViewController

@synthesize bmkButton, tabButton, spinner;
@synthesize awTitle, pgTitle, pgBar, search;
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
	
	pgBar.hidden = YES;
	pgTitle.hidden = YES;
	spinner.hidden = YES;
}

- (void)getOrUpdate:(id)sender {
	NSLog(@"Calling service");
	WeaveAppDelegate *app = (WeaveAppDelegate *)[[UIApplication sharedApplication] delegate];
	[[app service] loadBookmarksWithCallback:self];
	NSLog(@"Called!");
}

- (void)bookmarksDownloaded:(BOOL)success {
	pgTitle.hidden = YES;
	if (success)
		NSLog(@"DONE!");
	else
		NSLog(@"NOT DONE!");
}
/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

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
