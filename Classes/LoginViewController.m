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

#import "LoginViewController.h"
#import "WeaveAppDelegate.h"
#import "Service.h"

@implementation LoginViewController

@synthesize logo, process, spinner;
@synthesize username, password, passphrase;
@synthesize stLbl, usrField, pwdField, pphField;

-(void) verified:(BOOL)answer {
	if (answer) {
		[logo setAlpha:1.0];
		process = NO;
		
		/* Goto main view */
		WeaveAppDelegate *app = (WeaveAppDelegate *)[[UIApplication sharedApplication] delegate];
		[app switchLoginToMain];
	} else {
		/* Invalid credentials, try again */
		UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"Login failed" message:@"Your username, password or passphrase were incorrect.\nPlease try again!" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
		[alert show];
		[alert release];
		
		[stLbl setAlpha:0.0];
		[logo setAlpha:1.0];
		process = NO;
	}
}

-(BOOL) textFieldShouldReturn:(UITextField *)field {
	if (field == usrField) {
		[field resignFirstResponder];
		[pwdField becomeFirstResponder];
		return NO;
	} else if (field == pwdField) {
		[field resignFirstResponder];
		[pphField becomeFirstResponder];
		return NO;
	} else {
		[pphField resignFirstResponder];
		
		if (process == NO) {
			process = YES;
			[logo setAlpha:0.0]; 
			
			username = usrField.text;
			password = pwdField.text;
			passphrase = pphField.text;
			
			WeaveAppDelegate *app = (WeaveAppDelegate *)[[UIApplication sharedApplication] delegate];
			[app.service loadFromUser:username password:password passphrase:passphrase andCallback:self];
		}
		
		return YES;
	}
}

-(UILabel *) getStatusLabel {
	return stLbl;
}

-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


-(void) didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}


-(void) dealloc {
	[logo release];

	[usrField release];
	[pwdField release];
	[pphField release];
	
	[username release];
	[password release];
	[passphrase release];
	
    [super dealloc];
}

@end
