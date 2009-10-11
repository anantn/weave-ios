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

/* URL constants */
#define SERV_BASE	@"services.mozilla.com"
#define NODE_CHECK	@"https://auth.services.mozilla.com/user/1/%@/node/weave"

#define TABS_U		@"storage/tabs/?full=1"
#define HISTORY_U	@"storage/history/?full=1&sort=newest"
#define HISTORY_UP	@"storage/history/?full=1&sort=newest&newer=%f"
#define FAVICONS_U	@"https://services.mozilla.com/favicons/"
#define BMARKS_U	@"storage/bookmarks/?full=1"
#define BMARKS_UP	@"storage/bookmarks/?newer=%f"

#define PUBKEY_U	@"storage/keys/pubkey"
#define PRIVKEY_U	@"storage/keys/privkey"

/* Connection constants */
#define GOT_TABS			0
#define GOT_TABS_UP			1
#define GOT_BMARKS			2
#define GOT_HISTORY			3
#define BMARKS_PROGRESS		4
#define HISTORY_PROGRESS	5
#define GOT_BMARKS_UP		6
#define GOT_HISTORY_UP		7
#define GOT_FAVICONS		8
#define GOT_CLUSTER			9

@class Store, Crypto, Connection, LoginViewController;

@interface Service : NSObject <Responder> {
	id cb;
	int state;
	BOOL isFirst;
	int favsIndex;
	int totalRecords;
	int currentRecord;
	
	NSArray *favs;
	NSString *username;
	NSString *password;
	NSString *passphrase;
	
	Store *store;
	Crypto *crypto;
	Connection *conn;
}

@property (nonatomic, retain) id cb;
@property (nonatomic, copy) NSArray *favs;
@property (nonatomic, copy) NSString *username;
@property (nonatomic, copy) NSString *password;
@property (nonatomic, copy) NSString *passphrase;

@property (nonatomic, retain) Store *store;
@property (nonatomic, retain) Crypto *crypto;
@property (nonatomic, retain) Connection *conn;

-(Service *) init;

-(void) cryptoDone:(int)res;

/* Synchronous */
-(BOOL) loadFromStore;
/* Asynchronous */
-(void) loadFromUser:(NSString *)user password:(NSString *)pwd passphrase:(NSString *)ph andCallback:(id)callback;
-(void) loadDataWithCallback:(id)callback;
-(void) updateDataWithCallback:(id)callback;
-(void) successWithString:(NSString *)response andIndex:(int)i;
-(void) failureWithError:(NSError *)error andIndex:(int)i;

-(NSDate *)getSyncTime;

-(NSMutableArray *) getHistory;
-(NSMutableArray *) getBookmarks;
-(NSMutableDictionary *) getTabs;
-(NSMutableDictionary *) getIcons;
-(void) setTotal:(NSString *)stot;

@end
