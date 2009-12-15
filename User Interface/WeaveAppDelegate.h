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

#import "Store.h";

#import "SearchResultsController.h"
#import "TabBrowserController.h"
#import "BookmarkBrowserController.h"

@interface WeaveAppDelegate : NSObject <UIApplicationDelegate> {

  UIWindow*                 window;
  UIViewController*         rootController;
  UIView*                   contentView;
  UIView*                   headerView;
  UIActivityIndicatorView*  spinner;
  UILabel*                  spinMessage;
  UILabel*                  userNameDisplay;
  UITabBarController*       browserPage;
  SearchResultsController*  searchResults;
  TabBrowserController*     tabBrowser;
  BookmarkBrowserController*bookmarkBrowser;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UIViewController *rootController;

@property (nonatomic, retain) IBOutlet UIView* contentView;
@property (nonatomic, retain) IBOutlet UIView* headerView;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView* spinner;
@property (nonatomic, retain) IBOutlet UILabel* spinMessage;
@property (nonatomic, retain) IBOutlet UILabel* userNameDisplay;
@property (nonatomic, retain) IBOutlet UITabBarController *browserPage;
@property (nonatomic, retain) IBOutlet SearchResultsController *searchResults;
@property (nonatomic, retain) IBOutlet TabBrowserController *tabBrowser;
@property (nonatomic, retain) IBOutlet BookmarkBrowserController *bookmarkBrowser;


@end
