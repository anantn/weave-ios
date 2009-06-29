//
//  LoginViewController.h
//  Weave
//
//  Created by Anant Narayanan on 6/4/09.
//  Copyright 2009 Mozilla Corporation. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LoginViewController : UIViewController <UITextFieldDelegate> {
	BOOL process;
	
	UILabel *stLbl;
	UIImageView *logo;
	
	NSString *username;
	NSString *password;
	NSString *passphrase;
	
	UITextField *usrField;
	UITextField *pwdField;
	UITextField *pphField;
	
	UIActivityIndicatorView *spinner;
}

@property (nonatomic) BOOL process;

@property (nonatomic, copy) NSString *username;
@property (nonatomic, copy) NSString *password;
@property (nonatomic, copy) NSString *passphrase;

@property (nonatomic, retain) IBOutlet UIImageView *logo;
@property (nonatomic, retain) IBOutlet UITextField *usrField;
@property (nonatomic, retain) IBOutlet UITextField *pwdField;
@property (nonatomic, retain) IBOutlet UITextField *pphField;

@property (nonatomic, retain) IBOutlet UILabel *stLbl;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *spinner;

-(UILabel *) getStatusLabel;
-(void) verified:(BOOL)answer;

@end
