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

#import <UIKit/UIKit.h>


@interface TabViewController : UITabBarController <UITabBarControllerDelegate, UIAccelerometerDelegate> {
	UIView *overlay;
	UILabel *pgText;
	UILabel *pgStatus;
	UITableView *tView;
	UIProgressView *pgBar;
	
	BOOL okToUpdate;
}

@property (nonatomic, retain) IBOutlet UIView *overlay;
@property (nonatomic, retain) IBOutlet UILabel *pgText;
@property (nonatomic, retain) IBOutlet UILabel *pgStatus;
@property (nonatomic, retain) IBOutlet UITableView *tView;
@property (nonatomic, retain) IBOutlet UIProgressView *pgBar;

- (void)downloadComplete:(BOOL)success;
- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController;

@end
