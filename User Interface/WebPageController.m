//
//  WebPageController.m
//  Weave
//
//  Created by Dan Walkowski on 12/11/09.
//  Copyright 2009 ClownWare. All rights reserved.
//

#import "WebPageController.h"
#import "WeaveAppDelegate.h"

@implementation WebPageController

@synthesize webView;
@synthesize spinner;

- (id)initWithURL:(NSURL*)url
{
  if ((self = [super init])) 
  {
    _url = url;
  }
  return self;
}

- (void)done:(id)sender 
{
  WeaveAppDelegate* appDelegate = (WeaveAppDelegate *)[[UIApplication sharedApplication] delegate];
  [[appDelegate rootController] dismissModalViewControllerAnimated: YES];
}


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad 
{
  [super viewDidLoad];
  [webView loadRequest:[NSURLRequest requestWithURL:_url]];
}


- (void)webViewDidStartLoad:(UIWebView *)wv 
{
	[spinner startAnimating];
}

- (void)webViewDidFinishLoad:(UIWebView *)wv 
{
	[spinner stopAnimating];
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
