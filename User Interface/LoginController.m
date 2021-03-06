/***** BEGIN LICENSE BLOCK *****
 Version: MPL 1.1/GPL 2.0/LGPL 2.1
 
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
 Dan Walkowski <dan.walkowski@mozilla.com>

 Alternatively, the contents of this file may be used under the terms of either
 the GNU General Public License Version 2 or later (the "GPL"), or the GNU
 Lesser General Public License Version 2.1 or later (the "LGPL"), in which case
 the provisions of the GPL or the LGPL are applicable instead of those above.
 If you wish to allow use of your version of this file only under the terms of
 either the GPL or the LGPL, and not to allow others to use your version of
 this file under the terms of the MPL, indicate your decision by deleting the
 provisions above and replace them with the notice and other provisions
 required by the GPL or the LGPL. If you do not delete the provisions above, a
 recipient may use your version of this file under the terms of any one of the
 MPL, the GPL or the LGPL.
  
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
@synthesize spinner;

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
    
  //start spinner
  [spinner startAnimating];

  //the stockboy knows about the network
  if (![Stockboy hasConnectivity])
  {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Login Failed" message:@"There is no network access"
                                                   delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [alert show];
    [alert release];  
    [spinner stopAnimating];
    return NO;    
  }
  
  BOOL gotKey = [CryptoUtils fetchAndInstallPrivateKeyForUser:userNameField.text andPassword:passwordField.text andSecret:secretPhraseField.text];
  //stop spinner
  [spinner stopAnimating];
  
  if (!gotKey)
  {
      UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Login Failed" message:@"One or more fields are incorrect"
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
  
  [appDelegate installTabBar];

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
