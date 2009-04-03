//
//  WeaveConnection.h
//  Weave
//
//  Created by Anant Narayanan on 03/04/09.
//  Copyright 2009 Anant Narayanan. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WeaveService;

@interface WeaveConnection : NSObject {
	WeaveService *cb;
	NSMutableData *responseData;
}

@property (nonatomic, retain) WeaveService *cb;
@property (nonatomic, retain) NSMutableData *responseData;

-(void) getResource:(NSURL *)path withCallback:(WeaveService *)callback;

@end
