//
//  WebViewController.h
//  Weave
//
//  Created by Anant Narayanan on 6/15/09.
//  Copyright 2009 Mozilla Corporation. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface WebViewController : UIViewController {
	UIWebView *webView;
	UIToolbar *toolBar;
	UIBarItem *backButton;
}

@property (nonatomic, retain) IBOutlet UIWebView *webView;
@property (nonatomic, retain) IBOutlet UIToolbar *toolBar;
@property (nonatomic, retain) IBOutlet UIBarItem *backButton;

- (IBAction) backButton_clicked:(id)sender;

@end
