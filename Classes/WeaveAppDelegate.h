//
//  WeaveAppDelegate.h
//  Weave
//
//  Created by Anant Narayanan on 29/03/09.
//  Copyright Anant Narayanan 2009. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WeaveLoginViewController;

@interface WeaveAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    WeaveLoginViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet WeaveLoginViewController *viewController;

@end

