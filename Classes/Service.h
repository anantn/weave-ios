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

#import <Foundation/Foundation.h>
#import "JSON.h"
#import "Responder.h"

@class Store, Crypto, Connection, LoginViewController;

@interface Service : NSObject <Responder> {
	id cb;
	int favsIndex;
	NSArray *favs;
	NSString *server;
	
	NSString *username;
	NSString *password;
	NSString *passphrase;
	
	Store *store;
	Connection *conn;
}

@property (nonatomic, retain) id cb;
@property (nonatomic, copy) NSArray *favs;
@property (nonatomic, copy) NSString *server;

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
-(void) loadDataWithCallback:(id)callback;
-(void) updateDataWithCallback:(id)callback;
-(void) successWithString:(NSString *)response andIndex:(int)i;
-(void) failureWithError:(NSError *)error andIndex:(int)i;

-(NSDate *)getSyncTime;

-(NSMutableArray *) getTabs;
-(NSMutableArray *) getHistory;
-(NSMutableArray *) getBookmarks;
-(NSMutableDictionary *) getIcons;

@end
