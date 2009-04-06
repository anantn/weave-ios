//
//  WeaveLoginViewController.m
//  Weave
//
//  Created by Anant Narayanan on 29/03/09.
//  Copyright Anant Narayanan 2009. All rights reserved.
//

#import "WeaveService.h"
#import "WeaveAppDelegate.h"
#import "WeaveLoginViewController.h"

@implementation WeaveLoginViewController

@synthesize usrLabel, pwdLabel, pphLabel;
@synthesize usrField, pwdField, pphField;
@synthesize logo, spinner, submit, process;
@synthesize username, password, passphrase;

-(IBAction) login:(id)sender {
	if (process == NO) {
		process = YES;
		submit.enabled = NO;
		[logo setAlpha:0.0]; 
		[spinner setAlpha:1.0];
		[spinner startAnimating];
		
		username = usrField.text;
		password = pwdField.text;
		passphrase = pphField.text;
		
		WeaveAppDelegate *app = (WeaveAppDelegate *)[[UIApplication sharedApplication] delegate];
		[app.service verifyWithUsername:username password:password passphrase:passphrase andCallback:self];
	}
}

-(void) verified:(NSString *)answer {
	if (1) {
		UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"Alert" message:answer delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
		[alert show];
		[alert release];
		
		[spinner stopAnimating];
		[spinner setAlpha:0.0];
		[logo setAlpha:1.0];
		submit.enabled = YES;
		process = NO;
	} else {
		UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"Login failed" message:@"Your username, password or passphrase were incorrect.\nPlease try again!" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
		[alert show];
		[alert release];
		
		[spinner stopAnimating];
		[spinner setAlpha:0.0];
		[logo setAlpha:1.0];
		submit.enabled = YES;
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
	[submit release];
	
	[usrLabel release];
	[pwdLabel release];
	[pphLabel release];
	[usrField release];
	[pwdField release];
	[pphField release];
	
	[username release];
	[password release];
	[passphrase release];
	
    [super dealloc];
}

@end
