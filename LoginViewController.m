//
//  LoginViewController.m
//  Weave
//
//  Created by Anant Narayanan on 6/4/09.
//  Copyright 2009 Mozilla Corporation. All rights reserved.
//

#import "LoginViewController.h"
#import "WeaveAppDelegate.h"
#import "Service.h"

@implementation LoginViewController

@synthesize logo, process, pgLbl;
@synthesize stLbl, usrField, pwdField, pphField;
@synthesize username, password, passphrase, pgBar;

-(IBAction) login:(id)sender {
	if (process == NO) {
		process = YES;
		[logo setAlpha:0.0]; 
		
		username = usrField.text;
		password = pwdField.text;
		passphrase = pphField.text;
		
		WeaveAppDelegate *app = (WeaveAppDelegate *)[[UIApplication sharedApplication] delegate];
		[app.service loadFromUser:username password:password passphrase:passphrase andCallback:self];
	}
}

-(void) verified:(BOOL)answer {
	[pgBar setAlpha:0.0];
	if (answer) {
		[logo setAlpha:1.0];
		process = NO;
		
		/* Flip to main view */
		WeaveAppDelegate *app = (WeaveAppDelegate *)[[UIApplication sharedApplication] delegate];
		[app flip];
	} else {
		/* Invalid credentials, try again */
		UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"Login failed" message:@"Your username, password or passphrase were incorrect.\nPlease try again!" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
		[alert show];
		[alert release];
		
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
		[self login:pphField];
		return YES;
	}
}

-(UILabel *) getStatusLabel {
	return stLbl;
}

-(UILabel *) getProgressLabel {
	return pgLbl;
}

-(UIProgressView *) getProgressView {
	return pgBar;
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
