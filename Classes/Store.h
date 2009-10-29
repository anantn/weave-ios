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
#import <sqlite3.h>

//Changing this class to be a write-through cache.
// asking for data causes the encrypted data to be read from disk, decrypted, and cached in memory, for subsequent reads.
// setting new (encrypted) data flushes the cache, and overwrites the data on disk.  next read will cause a decrypt and cache.

//Note: at the moment, everything is still plaintext in the database, until I get the crypto moved over here
@class Service;

@interface Store : NSObject {
	sqlite3             *sqlDatabase;
	
  NSString *username;
  NSString *password;
  
  NSMutableDictionary *tabs;			// table from clientName -> array of [uri, title, favicon]
  NSMutableArray      *tabIndex;	// list of clientNames
	NSMutableDictionary *favicons;
  NSMutableArray      *history;
	NSMutableArray      *bookmarks;
}

//if the global is null, it loads the default store
+ (Store*) getStore;

//for creating a user when there is none
- (BOOL) setUser:(NSString*) newUser password:(NSString*) newPassword;

//for now, these are stored in the db. obviously this is not secure at all.
- (NSString*) getUsername;
- (NSString*) getPassword;

- (NSDictionary*)  getTabs;
- (NSArray*)       getTabIndex;
- (NSDictionary*)  getFavicons;
- (NSArray*)       getHistory;
- (NSArray*)       getBookmarks;

- (BOOL) addTab:(NSString *)JSONObject withID:(NSString*)theID;  //tabIndex computed
- (BOOL) setFavicons:(NSString *)JSONObject withID:(NSString*)theID;
- (BOOL) addBookmarkRecord:(NSString *)json withID:(NSString*)theID;
- (BOOL) addHistoryRecord:(NSString *)json withID:(NSString*)theID;


- (BOOL) setSyncTimeToNow;
- (double) getSyncTime;

@end
