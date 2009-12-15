//
//  LoginController.h
//  Weave
//
//  Created by Dan Walkowski on 12/9/09.
//  Copyright 2009 ClownWare. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface LoginController : UIViewController <UITextFieldDelegate, UIAlertViewDelegate>
{
  UITextField *userNameField;
	UITextField *passwordField;
	UITextField *secretPhraseField;
}

@property (nonatomic, retain) IBOutlet UITextField *userNameField;
@property (nonatomic, retain) IBOutlet UITextField *passwordField;
@property (nonatomic, retain) IBOutlet UITextField *secretPhraseField;

@end
