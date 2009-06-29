//
//  WebViewController.h
//  Weave
//
//  Created by Anant Narayanan on 6/15/09.
//  Copyright 2009 Mozilla Corporation. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WebViewController : UIViewController <UIWebViewDelegate> {
	UIView *ex;
	UILabel *pt;
	UIWebView *webView;
	UIBarItem *backButton;
	UIActivityIndicatorView *spinner;
}

@property (nonatomic, retain) IBOutlet UIView *ex;
@property (nonatomic, retain) IBOutlet UILabel *pt;
@property (nonatomic, retain) IBOutlet UIWebView *webView;
@property (nonatomic, retain) IBOutlet UIBarItem *backButton;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *spinner;

-(void)loadURI:(NSString *)uri;

-(IBAction)backButton_clicked:(id)sender;
-(IBAction)browser_back:(id)sender;
-(IBAction)browser_forward:(id)sender;

-(IBAction)showExtraMenu;
-(IBAction)hideExtraMenu;
-(IBAction)extra_mail:(id)sender;
-(IBAction)extra_safari:(id)sender;

-(void)webViewDidStartLoad:(UIWebView *)webView;
-(void)webViewDidFinishLoad:(UIWebView *)webView;

@end
