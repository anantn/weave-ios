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

#import "Store.h"
#import "Stockboy.h"
#import "WeaveAppDelegate.h"
#import "LoginController.h"
#import "Reachability.h"

#import <QuartzCore/QuartzCore.h>

@implementation WeaveAppDelegate

@synthesize window;
@synthesize rootController;

@synthesize contentView;
@synthesize headerView;
@synthesize spinner;
@synthesize spinMessage;
@synthesize syncButton;
@synthesize userNameDisplay;
@synthesize browserPage;
@synthesize searchResults;
@synthesize tabBrowser;
@synthesize bookmarkBrowser;





-(void) applicationDidFinishLaunching:(UIApplication *)application 
{
  
  //a bit too many globals, but I want a handle to these guys so I can poke them
  searchResults = [[browserPage viewControllers] objectAtIndex:0];
  tabBrowser = [[browserPage viewControllers] objectAtIndex:1];
  bookmarkBrowser = [[browserPage viewControllers] objectAtIndex:2];
  
  // Start on search page every time   
  UIView* tabContentView = [browserPage view];
	[contentView addSubview:tabContentView]; 
  
  CGRect frame = tabContentView.frame;
  frame.size.height -= headerView.frame.size.height + 20;  //status bar height
  tabContentView.frame = frame;
  
	// Show window
  [window addSubview:rootController.view];
	[window makeKeyAndVisible];
  
  NSString* user = [[Store getStore] getUsername];
  
	if (user == nil) //we should check for existence of the private key here
  {    
    LoginController *loginController = [[LoginController alloc] init];
    [rootController presentModalViewController: loginController animated:YES];
	  [loginController release];
	} 
  else 
  {
    userNameDisplay.text = user;
    [Stockboy restock];
	}
}


- (IBAction) resync:(id)sender
{
  [Stockboy restock];
}

- (void) startSpinner
{
  //hide the button, show the label, animate the spinner
  [self.syncButton setHidden:YES];
  [self.spinner startAnimating];
  [self.spinMessage setHidden:NO];

}


- (void) stopSpinner
{
  //hide the label, show the button, stop the spinner
  [self.syncButton setHidden:NO];
  [self.spinner stopAnimating];
  [self.spinMessage setHidden:YES];
}


- (void) refreshViews
{
  [searchResults refresh];
  [tabBrowser refresh];
  [bookmarkBrowser refresh];
}

-(void) dealloc {
  [browserPage release];
  [window release];
	[super dealloc];
}



@end
