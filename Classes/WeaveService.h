//
//  WeaveService.h
//  Weave
//
//  Created by Anant Narayanan on 31/03/09.
//  Copyright 2009 Anant Narayanan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JSON/JSON.h>
#import "WeaveConnection.h"
#import "WeaveVerify.h"

@interface WeaveService : NSObject <WeaveResponder> {
	id cb;
	NSString *server;
	NSString *baseURI;
	NSString *protocol;
	
	NSString *username;
	NSString *password;
	NSString *passphrase;
	
	NSString *iv;
	NSString *salt;
	NSString *public_key;
	NSString *private_key;
	
	WeaveConnection *conn;
}

@property (nonatomic, copy) id cb;
@property (nonatomic, copy) NSString *server;
@property (nonatomic, copy) NSString *baseURI;
@property (nonatomic, copy) NSString *protocol;

@property (nonatomic, copy) NSString *username;
@property (nonatomic, copy) NSString *password;
@property (nonatomic, copy) NSString *passphrase;

@property (nonatomic, copy) NSString *iv;
@property (nonatomic, copy) NSString *salt;
@property (nonatomic, copy) NSString *public_key;
@property (nonatomic, copy) NSString *private_key;

@property (nonatomic, retain) WeaveConnection *conn;

-(WeaveService *) initWithServer:(NSString *)server;

-(void) verifyWithUsername:(NSString *)user password:(NSString *)pwd passphrase:(NSString *)ph andCallback:(id <WeaveVerify>)cb;
-(void) successWithString:(NSString *)response andIndex:(int)i;
-(void) failureWithError:(NSError *)error andIndex:(int)i;

-(void) setCluster;

@end
