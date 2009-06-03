//
//  Connection.h
//  Weave
//
//  Created by Anant Narayanan on 03/04/09.
//  Copyright 2009 Anant Narayanan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Responder.h"

@interface Connection : NSObject {
	id cb;
	int index;
	NSMutableData *responseData;
}

@property (nonatomic, retain) id cb;
@property (nonatomic, retain) NSMutableData *responseData;

-(void) getResource:(NSURL *)path withCallback:(id <Responder>)callback andIndex:(int)i;

@end