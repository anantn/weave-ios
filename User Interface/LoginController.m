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

#import "LoginController.h"
#import "Store.h"
#import "CryptoUtils.h"
#import "Stockboy.h"
#import "WeaveAppDelegate.h"


@implementation LoginController

@synthesize userNameField;
@synthesize passwordField;
@synthesize secretPhraseField;

-(BOOL) textFieldShouldReturn:(UITextField *)field 
{
  //check that all the fields have contents
  if (userNameField.text == nil || userNameField.text.length == 0)
  {
    [userNameField becomeFirstResponder];
    return NO;
  }
  
  if (passwordField.text == nil || passwordField.text.length == 0)
  {
    [passwordField becomeFirstResponder];
    return NO;
  }
  
  if (secretPhraseField.text == nil || secretPhraseField.text.length == 0)
  {
    [secretPhraseField becomeFirstResponder];
    return NO;
  }
    
  
  if (![CryptoUtils fetchAndInstallPrivateKeyForUser:userNameField.text andPassword:passwordField.text andSecret:secretPhraseField.text])
  {
      UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Login Failed" message:@"One or more fields are incorrect."
                                                     delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
      [alert show];
      [alert release];    
      return NO;    
  }
  
  WeaveAppDelegate* appDelegate = (WeaveAppDelegate *)[[UIApplication sharedApplication] delegate];
  
  appDelegate.userNameDisplay.text = userNameField.text;

  [[Store getStore] setUser:userNameField.text password:passwordField.text];
  [CryptoUtils fetchAndUpdateClientsforUser:userNameField.text andPassword:passwordField.text];
  [Stockboy restock];
  
  [[appDelegate rootController] dismissModalViewControllerAnimated: YES];
  
  return YES;
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
