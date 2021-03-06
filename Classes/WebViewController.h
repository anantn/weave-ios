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
