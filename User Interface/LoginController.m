//
//  LoginController.m
//  Weave
//
//  Created by Dan Walkowski on 12/9/09.
//  Copyright 2009 ClownWare. All rights reserved.
//

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
