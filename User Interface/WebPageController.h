//
//  WebPageController.h
//  Weave
//
//  Created by Dan Walkowski on 12/11/09.
//  Copyright 2009 ClownWare. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface WebPageController : UIViewController <UIWebViewDelegate>
{
  NSURL* _url;
  UIWebView* webView;
  UIActivityIndicatorView* spinner;
  
}

@property (nonatomic, retain) IBOutlet UIWebView *webView;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *spinner;

-(IBAction)done:(id)sender;

@end
