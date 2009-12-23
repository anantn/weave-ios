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
 Dan Walkowski <dan.walkowski@gmail.com>
 
 ***** END LICENSE BLOCK *****/

#import "TapActionController.h"
#import "WeaveAppDelegate.h"
#import "WebPageController.h"
#import "Stockboy.h"

@implementation TapActionController

- (id) initWithDescription:(NSString*)desc andLocation:(NSString*)loc
{
  if ((self = [super init])) 
  {
    description = [desc retain];
    location = [loc retain];
  }
  return self;
}

//this presents the 'what do you want to do now?' sheet that slides up when you choose a web destination from any of the lists
- (void) chooseAction
{
  if ([Stockboy hasConnectivity])
  {
    UIActionSheet *action = [[UIActionSheet alloc]initWithTitle:description delegate:self cancelButtonTitle:@"Cancel" 
                                         destructiveButtonTitle:nil 
                                              otherButtonTitles:@"View in Safari", @"Email URL", @"Preview", nil];
    

    WeaveAppDelegate* appDelegate = (WeaveAppDelegate *)[[UIApplication sharedApplication] delegate];
    [action showFromTabBar:appDelegate.browserPage.tabBar];
    [action release];
  }
  else //no network
  {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"There is no network access"
                                                   delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [alert show];
    [alert release];    
  }
}


- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{  
  switch (buttonIndex)
  {
    case 0: //safari
    {
      if (![[UIApplication sharedApplication] openURL:[NSURL URLWithString:location]])
      {
        NSLog(@"Unable to open url '%@'", location);
      }
      break;
    }
    case 1: //email
    {
      NSString *content = [NSString stringWithFormat:@"subject=Sending you a link&body=Here is that URL we talked about:\n%@", location];  
      NSString *mailto = [NSString stringWithFormat:@"mailto:?%@", [content stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];  
      NSURL *url = [NSURL URLWithString:mailto];  
      if (![[UIApplication sharedApplication] openURL:url])
      {
        NSLog(@"Unable to send email '%@'", mailto);
      }
      
      break;
    }
    case 2: //preview
    {
      WebPageController* webPage = [[WebPageController alloc] initWithURL:[NSURL URLWithString:location]];
      webPage.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
      WeaveAppDelegate* appDelegate = (WeaveAppDelegate *)[[UIApplication sharedApplication] delegate];
      
      [[appDelegate rootController] presentModalViewController: webPage animated:YES];
      [webPage release];
      
      break;
    }
    case 3: //cancel, do nothing
    {
      break;
    }
  }
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


- (void)dealloc 
{
  [location release];
  [description release];
  [super dealloc];
}


@end
