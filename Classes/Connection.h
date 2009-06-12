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
	BOOL success;
	NSString *user;
	NSString *pass;
	NSString *phrase;
	NSMutableData *responseData;
}

@property (nonatomic) BOOL success;
@property (nonatomic, retain) id cb;

@property (nonatomic, copy) NSString *user;
@property (nonatomic, copy) NSString *pass;
@property (nonatomic, copy) NSString *phrase;

@property (nonatomic, retain) NSMutableData *responseData;



-(void) setUser:(NSString *)u password:(NSString *)p andPassphrase:(NSString *)ph;
-(void) getResource:(NSURL *)url withCallback:(id <Responder>)callback andIndex:(int)i;

@end
