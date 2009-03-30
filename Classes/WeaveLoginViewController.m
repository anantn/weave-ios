//
//  WeaveLoginViewController.m
//  Weave
//
//  Created by Anant Narayanan on 29/03/09.
//  Copyright Anant Narayanan 2009. All rights reserved.
//

#import "WeaveLoginViewController.h"

@implementation WeaveLoginViewController

@synthesize usrLabel, pwdLabel, pphLabel;
@synthesize usrField, pwdField, pphField;
@synthesize logo, spinner, submit, process;
@synthesize username, password, passphrase;

- (IBAction)login:(id)sender {
	if (self.process == NO) {
		self.process = YES;
		self.submit.enabled = NO;
		[self.logo removeFromSuperview]; 
		[self.spinner setAlpha:1.0];
		[self.spinner startAnimating];
		
		self.username = usrField.text;
		self.password = pwdField.text;
		self.passphrase = pphField.text;
	}
}

- (BOOL)textFieldShouldReturn:(UITextField *)field {
	[field resignFirstResponder];
	return YES;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}


- (void)dealloc {
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
