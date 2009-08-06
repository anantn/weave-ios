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

@class Service;

@interface Store : NSObject {
	sqlite3 *dataBase;
	
	NSMutableArray *history;
	NSMutableArray *bookmarks;
	
	NSMutableDictionary *tabs;
	NSMutableDictionary *favicons;
}

@property (nonatomic) sqlite3 *dataBase;

@property (nonatomic, retain) NSMutableArray *history;
@property (nonatomic, retain) NSMutableArray *bookmarks;
@property (nonatomic, retain) NSMutableDictionary *tabs;
@property (nonatomic, retain) NSMutableDictionary *favicons;

-(Store *) initWithDB:(NSString *)db;

-(BOOL) addTabs:(NSString *)json;
-(BOOL) addHistory:(NSString *)json;
-(BOOL) addFavicons:(NSString *)json;
-(BOOL) addBookmarks:(NSString *)json;

-(BOOL) loadUserToService:(Service *)svc;
-(BOOL) addUserWithService:(Service *)svc;
-(BOOL) setSyncTimeForUser:(NSString *)user;
-(double) getSyncTimeForUser:(NSString *)user;

-(int) getUsers;

@end
