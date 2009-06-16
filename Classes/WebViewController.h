//
//  WebViewController.h
//  Weave
//
//  Created by Anant Narayanan on 6/15/09.
//  Copyright 2009 Mozilla Corporation. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface WebViewController : UIViewController <UIWebViewDelegate> {
	UIWebView *webView;
	UIToolbar *toolBar;
	UIBarItem *backButton;
	UIActivityIndicatorView *spinner;
}

@property (nonatomic, retain) IBOutlet UIWebView *webView;
@property (nonatomic, retain) IBOutlet UIToolbar *toolBar;
@property (nonatomic, retain) IBOutlet UIBarItem *backButton;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *spinner;

- (IBAction) backButton_clicked:(id)sender;
- (void)webViewDidStartLoad:(UIWebView *)webView;
- (void)webViewDidFinishLoad:(UIWebView *)webView;

@end
