//
//  WebViewController.m
//  Weave
//
//  Created by Anant Narayanan on 6/15/09.
//  Copyright 2009 Mozilla Corporation. All rights reserved.
//

#import "WebViewController.h"
#import "WeaveAppDelegate.h"
#import <QuartzCore/QuartzCore.h>

@implementation WebViewController

@synthesize webView, backButton, spinner, pt, ex;

- (void)viewDidLoad {
    [super viewDidLoad];
	[webView setScalesPageToFit:YES];
}

-(void)loadURI:(NSString *)uri {
	[webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:uri]]];
	[pt setText:[[[webView request] URL] host]];
	pt.hidden = NO;
}

-(void)showExtraMenu {
	CATransition *tr = [CATransition animation];
	tr.duration = 0.75;
	tr.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
	
	tr.type = kCATransitionMoveIn;
	tr.subtype = kCATransitionFromTop;
	
	[self.view.window addSubview:ex];
	[ex.layer addAnimation:tr forKey:nil];
	
	ex.hidden = NO;
}

-(void)hideExtraMenu {
	CATransition *tr = [CATransition animation];
	tr.duration = 0.75;
	tr.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
	
	tr.type = kCATransitionPush;
	tr.subtype = kCATransitionFromBottom;
	
	[ex.layer addAnimation:tr forKey:nil];
	ex.hidden = YES;
}

- (void)extra_mail:(id)sender {
	NSURL *url = [[NSURL alloc]
				  initWithString:[NSString
								  stringWithFormat:@"mailto:?body=%@", [[[webView request] URL] absoluteString]]];
	[[UIApplication sharedApplication] openURL:url];
}

- (void)extra_safari:(id)sender {
	[[UIApplication sharedApplication] openURL:[[webView request] URL]];
}

- (void)backButton_clicked:(id)sender {
	WeaveAppDelegate *app = (WeaveAppDelegate *)[[UIApplication sharedApplication] delegate];
	[app switchWebToMain];
}

- (void)browser_back:(id)sender {
	[[self webView] goBack];
}

- (void)browser_forward:(id)sender {
	[[self webView] goForward];
}

/* Web view delegate */
- (void)webViewDidStartLoad:(UIWebView *)wv {
	[pt setText:[[[wv request] URL] host]];
	[spinner startAnimating];
	spinner.hidden = NO;}

- (void)webViewDidFinishLoad:(UIWebView *)wv {
	[spinner stopAnimating];
	spinner.hidden = YES;
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
