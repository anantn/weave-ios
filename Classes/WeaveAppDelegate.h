//
//  WeaveAppDelegate.h
//  Weave
//
//  Created by Anant Narayanan on 29/03/09.
//  Copyright Anant Narayanan 2009. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Service;

@interface WeaveAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
	Service *service;
}

@property (retain) Service *service;
@property (nonatomic, retain) IBOutlet UIWindow *window;

@end
