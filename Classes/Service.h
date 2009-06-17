//
//  Service.h
//  Weave
//
//  Created by Anant Narayanan on 31/03/09.
//  Copyright 2009 Anant Narayanan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JSON/JSON.h>
#import "Responder.h"

@class Store, Crypto, Connection, LoginViewController;

@interface Service : NSObject <Responder> {
	id cb;
	NSString *server;
	NSString *baseURI;
	NSString *protocol;
	
	NSString *username;
	NSString *password;
	NSString *passphrase;
	
	Store *store;
	Connection *conn;
}

@property (nonatomic, retain) id cb;
@property (nonatomic, copy) NSString *server;
@property (nonatomic, copy) NSString *baseURI;
@property (nonatomic, copy) NSString *protocol;

@property (nonatomic, copy) NSString *username;
@property (nonatomic, copy) NSString *password;
@property (nonatomic, copy) NSString *passphrase;

@property (nonatomic, retain) Store *store;
@property (nonatomic, retain) Connection *conn;

-(Service *) initWithServer:(NSString *)server;

/* Synchronous */
-(BOOL) loadFromStore;
/* Asynchronous */
-(void) loadFromUser:(NSString *)user password:(NSString *)pwd passphrase:(NSString *)ph andCallback:(id)callback;
-(void) loadBookmarksWithCallback:(id)callback;

-(void) successWithString:(NSString *)response andIndex:(int)i;
-(void) failureWithError:(NSError *)error andIndex:(int)i;

-(NSMutableArray *) getBookmarkURIs;
-(NSMutableArray *) getBookmarkTitles;
-(NSMutableArray *) getHistoryURIs;
-(NSMutableArray *) getHistoryTitles;
-(NSMutableArray *) getTabURIs;
-(NSMutableArray *) getTabTitles;

@end
