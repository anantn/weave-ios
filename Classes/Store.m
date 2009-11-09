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

#import "Store.h"
#import "Utility.h"
#import "JSON.h"


/* 
CREATE TABLE moz_favicons (url LONGVARCHAR PRIMARY KEY, image LONGVARCHAR);
CREATE TABLE moz_places (id INTEGER PRIMARY KEY, guid LONGVARCHAR, type LONGVARCHAR, url LONGVARCHAR, title LONGVARCHAR, client LONGVARCHAR, favicon LONGVARCHAR);
CREATE TABLE users (id INTEGER PRIMARY KEY AUTOINCREMENT, uid LONGVARCHAR, password LONGVARCHAR, last_bmarks_sync INTEGER, last_hist_sync INTEGER);
*/

#define PLACES_ID_COLUMN      0
#define PLACES_GUID_COLUMN    1
#define PLACES_TYPE_COLUMN    2
#define PLACES_URL_COLUMN     3
#define PLACES_TITLE_COLUMN   4
#define PLACES_CLIENT_COLUMN  5
#define PLACES_FAVICON_COLUMN 6


@interface Store (Private)
-(Store *) initWithDBFile:(NSString *)filePath;
- (void) loadUserInfo;
- (void) loadExistingTabs;
- (void) loadExistingHistory;
- (void) loadExistingBookmarks;
- (void) loadExistingFavicons;
@end

@implementation Store

// The singleton instance
static Store* _gStore = nil;


//CLASS METHODS////////
+ (Store*)getStore
{
  if (_gStore == nil)
    _gStore = [[[Store alloc] initWithDBFile:@"/store.sq3"] retain];
  return _gStore;
}


-(Store *) initWithDBFile:(NSString *)filePath 
{
	self = [super init];
	
	if (self) 
	{
		BOOL success;
		NSError *error;
				
		username = nil;
		password = nil;
		tabIndex = [[NSMutableArray alloc] init];
		
		NSFileManager *fm = [NSFileManager defaultManager];
		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		NSString *documentsDir = [paths objectAtIndex:0];
		NSString *writablePath = [documentsDir stringByAppendingString:filePath];
		
		/* DB already exists */
		success = [fm fileExistsAtPath:writablePath];
		if (success) 
		{
			NSLog(@"Existing DB found, using");
			if (sqlite3_open([writablePath UTF8String], &sqlDatabase) == SQLITE_OK) 
			{
				[self loadUserInfo];
				[self loadExistingTabs];
				[self loadExistingHistory];
				[self loadExistingBookmarks];
				[self loadExistingFavicons];
				return self;
			} 
			else 
			{
				NSLog(@"Could not open database!");
				// TODO this should be a fatal
				return NULL;
			}
		}
		
		/* DB doesn't exist, copy from resource bundle */
		NSString *defaultDB = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:filePath];
		
		success = [fm copyItemAtPath:defaultDB toPath:writablePath error:&error];
		if (success) {
			if (sqlite3_open([writablePath UTF8String], &sqlDatabase) == SQLITE_OK) {
				tabs = [[NSMutableDictionary alloc] init];
				history = [[NSMutableArray alloc] init];
				bookmarks = [[NSMutableArray alloc] init];
				favicons = [[NSMutableDictionary alloc] init];
				return self;
			} else {
				NSLog(@"Could not open database!");
			}
		} else {
			NSLog(@"Could not create database!");
			NSLog(@"%@", [error localizedDescription]);
		}
	}
	return NULL;
}

- (BOOL) setUser:(NSString*) newUser password:(NSString*) newPassword
{
	sqlite3_stmt *sqlStatement;
	const char *insertUserSQL = "INSERT INTO users ('uid', 'password') VALUES (?, ?)";

	if (sqlite3_prepare_v2(sqlDatabase, insertUserSQL, -1, &sqlStatement, NULL) != SQLITE_OK) 
  {
		NSLog(@"Could not prepare statement!");
		return NO;
	} 
  else 
  {
		sqlite3_bind_text(sqlStatement, 1, [newUser UTF8String], -1, SQLITE_TRANSIENT);
		sqlite3_bind_text(sqlStatement, 2, [newPassword UTF8String], -1, SQLITE_TRANSIENT);
		
		if (sqlite3_step(sqlStatement) != SQLITE_DONE) 
    {
			NSLog(@"Could not save user to DB!");
			sqlite3_finalize(sqlStatement);
			return NO;
		}
		username = newUser;
		password = newPassword;
	}
	
	sqlite3_finalize(sqlStatement);
	return YES;
}

-(double) getBookmarksSyncTime
{
	double time;
	sqlite3_stmt *stmnt;
	const char *sql = "SELECT last_bmarks_sync FROM users WHERE uid = ?";

	if (sqlite3_prepare_v2(sqlDatabase, sql, -1, &stmnt, NULL) != SQLITE_OK) 
  {
		NSLog(@"Could not prepare statement (load time)!");
		return 0;
	} 
  else 
  {
		sqlite3_bind_text(stmnt, 1, [username UTF8String], -1, SQLITE_TRANSIENT);
		if (sqlite3_step(stmnt) == SQLITE_ROW) 
    {
			time = sqlite3_column_double(stmnt, 0);
		} 
    else 
    {
			NSLog(@"Could not execute SQL to load bmarks sync time!");
			sqlite3_finalize(stmnt);
			return 0;
		}		
	}
	
	return time;
}

-(double) getHistorySyncTime
{
	double time;
	sqlite3_stmt *stmnt;
	const char *sql = "SELECT last_hist_sync FROM users WHERE uid = ?";
  
	if (sqlite3_prepare_v2(sqlDatabase, sql, -1, &stmnt, NULL) != SQLITE_OK) 
  {
		NSLog(@"Could not prepare statement (load time)!");
		return 0;
	} 
  else 
  {
		sqlite3_bind_text(stmnt, 1, [username UTF8String], -1, SQLITE_TRANSIENT);
		if (sqlite3_step(stmnt) == SQLITE_ROW) 
    {
			time = sqlite3_column_double(stmnt, 0);
		} 
    else 
    {
			NSLog(@"Could not execute SQL to load bmarks sync time!");
			sqlite3_finalize(stmnt);
			return 0;
		}		
	}
	
	return time;
}


-(BOOL) updateBookmarksSyncTime
{
	sqlite3_stmt *stmnt;
	const char *sql = "UPDATE users SET last_bmarks_sync = ? WHERE uid = ?";
	
	if (sqlite3_prepare_v2(sqlDatabase, sql, -1, &stmnt, NULL) != SQLITE_OK) 
  {
		NSLog(@"Could not prepare statement (set time)!");
		return NO;
	} 
  else 
  {
		sqlite3_bind_double(stmnt, 1, [[NSDate date] timeIntervalSince1970]);
		sqlite3_bind_text(stmnt, 2, [username UTF8String], -1, SQLITE_TRANSIENT);
		if (sqlite3_step(stmnt) != SQLITE_DONE) 
    {
			NSLog(@"Could not execute SQL to update bmarks sync time for user!");
			sqlite3_finalize(stmnt);
			return NO;
		}
	}
	
	sqlite3_finalize(stmnt);
	return YES;	
}

-(BOOL) updateHistorySyncTime
{
	sqlite3_stmt *stmnt;
	const char *sql = "UPDATE users SET last_hist_sync = ? WHERE uid = ?";
	
	if (sqlite3_prepare_v2(sqlDatabase, sql, -1, &stmnt, NULL) != SQLITE_OK) 
  {
		NSLog(@"Could not prepare statement (set time)!");
		return NO;
	} 
  else 
  {
		sqlite3_bind_double(stmnt, 1, [[NSDate date] timeIntervalSince1970]);
		sqlite3_bind_text(stmnt, 2, [username UTF8String], -1, SQLITE_TRANSIENT);
		if (sqlite3_step(stmnt) != SQLITE_DONE) 
    {
			NSLog(@"Could not execute SQL to update history sync time for user!");
			sqlite3_finalize(stmnt);
			return NO;
		}
	}
	
	sqlite3_finalize(stmnt);
	return YES;	
}

-(BOOL) beginTransaction
{
	sqlite3_stmt *stmnt;
	const char *sql = "BEGIN IMMEDIATE TRANSACTION";
	
	if (sqlite3_prepare_v2(sqlDatabase, sql, -1, &stmnt, NULL) != SQLITE_OK) 
  {
		NSLog(@"Could not prepare statement BEGIN IMMEDIATE TRANSACTION!");
		return NO;
	} 
  else 
  {
		if (sqlite3_step(stmnt) != SQLITE_DONE) 
    {
			NSLog(@"Could not open transaction");
			sqlite3_finalize(stmnt);
			return NO;
		}
	}
	
	sqlite3_finalize(stmnt);
	return YES;	
}

-(BOOL) endTransaction
{
	sqlite3_stmt *stmnt;
	const char *sql = "COMMIT TRANSACTION";
	
	if (sqlite3_prepare_v2(sqlDatabase, sql, -1, &stmnt, NULL) != SQLITE_OK) 
  {
		NSLog(@"Could not prepare statement COMMIT TRANSACTION!");
		return NO;
	} 
  else 
  {
		if (sqlite3_step(stmnt) != SQLITE_DONE) 
    {
			NSLog(@"Could not commit transaction");
			sqlite3_finalize(stmnt);
			return NO;
		}
	}
	
	sqlite3_finalize(stmnt);
	return YES;	
}


-(BOOL) storePlaceInDB:(NSString *)type withURI:(NSString *)uri title:(NSString *)title andFavicon:(NSString *)favicon andID:(NSString*)theID maybeClient:(NSString *)client {
	const char *sql;
	sqlite3_stmt *stmnt;
	
	if ([type isEqualToString:@"bookmark"])
		sql = "INSERT INTO moz_places ('guid', 'type', 'url', 'title', 'favicon') VALUES (?, 'bookmark', ?, ?, ?)";
	else if ([type isEqualToString:@"history"])
		sql = "INSERT INTO moz_places ('guid', 'type', 'url', 'title', 'favicon') VALUES (?, 'history', ?, ?, ?)";
	else {
		if (client != nil)
			sql = "INSERT INTO moz_places ('guid', 'type', 'url', 'title', 'client', 'favicon') VALUES (?, 'tab', ?, ?, ?, ?)";
		else
			return NO;
	}
	
	if (sqlite3_prepare_v2(sqlDatabase, sql, -1, &stmnt, NULL) != SQLITE_OK) {
		NSLog(@"Could not prepare statement!");
		return NO;
	} else {
		sqlite3_bind_text(stmnt, 1, [theID UTF8String], -1, SQLITE_TRANSIENT);
		sqlite3_bind_text(stmnt, 2, [uri UTF8String], -1, SQLITE_TRANSIENT);
		sqlite3_bind_text(stmnt, 3, [title UTF8String], -1, SQLITE_TRANSIENT);

		if ([type isEqualToString:@"tab"]) {
			sqlite3_bind_text(stmnt, 4, [client UTF8String], -1, SQLITE_TRANSIENT);
			sqlite3_bind_text(stmnt, 5, [favicon UTF8String], -1, SQLITE_TRANSIENT);
		} else {
			sqlite3_bind_text(stmnt, 4, [favicon UTF8String], -1, SQLITE_TRANSIENT);
		}
		
		if (sqlite3_step(stmnt) != SQLITE_DONE) {
			int resultCode = sqlite3_finalize(stmnt);
			NSLog(@"Could not save place to DB! (error code %d)", resultCode);
			return NO;
		}
	}
	sqlite3_finalize(stmnt);
	return YES;
}

-(BOOL) storePlaceInDB:(NSString *)type withURI:(NSString *)uri title:(NSString *)title andFavicon:(NSString *)favicon andID:(NSString*)theID {
	return [self storePlaceInDB:type withURI:uri title:title andFavicon:favicon andID:theID maybeClient:nil];
}

-(BOOL) removePlaceFromDB:(NSString *)theID
{
	const char *sql;
	sqlite3_stmt *stmnt;
	
	sql = "DELETE FROM moz_places where guid = ?";
	if (sqlite3_prepare_v2(sqlDatabase, sql, -1, &stmnt, NULL) != SQLITE_OK) {
		NSLog(@"Could not prepare statement!");
		return NO;
	} else {
		sqlite3_bind_text(stmnt, 1, [theID UTF8String], -1, SQLITE_TRANSIENT);
		if (sqlite3_step(stmnt) != SQLITE_DONE) {
			NSLog(@"Could not remove place from DB!");
			sqlite3_finalize(stmnt);
			return NO;
		}
	}
	sqlite3_finalize(stmnt);
	return YES;
}

-(BOOL) removeTypeFromDB:(NSString *)theType
{
	const char *sql;
	sqlite3_stmt *stmnt;
	
	sql = "DELETE FROM moz_places where type = ?";
	if (sqlite3_prepare_v2(sqlDatabase, sql, -1, &stmnt, NULL) != SQLITE_OK) {
		NSLog(@"Could not prepare statement!");
		return NO;
	} else {
		sqlite3_bind_text(stmnt, 1, [theType UTF8String], -1, SQLITE_TRANSIENT);
		if (sqlite3_step(stmnt) != SQLITE_DONE) {
			NSLog(@"Could not remove the type from DB!");
			sqlite3_finalize(stmnt);
			return NO;
		}
	}
	sqlite3_finalize(stmnt);
	return YES;
}


///////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////
- (void) loadUserInfo
{
  sqlite3_stmt *dbStatement;
  const char *userQuery = "SELECT * FROM users LIMIT 1";

  if (sqlite3_prepare_v2(sqlDatabase, userQuery, -1, &dbStatement, NULL) == SQLITE_OK) 
  {
    if (sqlite3_step(dbStatement) == SQLITE_ROW) 
    {
      username = [[NSString stringWithUTF8String:(char *)sqlite3_column_text(dbStatement, 1)] retain];
      password = [[NSString stringWithUTF8String:(char *)sqlite3_column_text(dbStatement, 2)] retain];
    } 
    sqlite3_finalize(dbStatement);
  } 
}

///////////////////////////////////////////////////////////////////////
- (NSString*) getUsername
{
  return username;
}

- (NSString*) getPassword
{
  return password;
}

- (NSDictionary*)  getTabs
{
	return tabs;
}

- (NSArray*) getTabIndex
{
  return tabIndex;
}

- (NSDictionary*) getFavicons
{
	return favicons;
}

- (NSArray*) getHistory
{
	return history;
}

- (NSArray*) getBookmarks
{
  return bookmarks;
}


///////////////////////////////////////////////////////////////////////

-(void)loadExistingTabs
{
	sqlite3_stmt *dbStatement;
	const char *tabQuery = "SELECT * FROM moz_places WHERE type = 'tab'";
	NSString* icon;
	
	tabs = [[NSMutableDictionary alloc] init];
	
	if (sqlite3_prepare_v2(sqlDatabase, tabQuery, -1, &dbStatement, NULL) == SQLITE_OK) 
	{
		while (sqlite3_step(dbStatement) == SQLITE_ROW) 
		{
			if ((char *)sqlite3_column_text(dbStatement, PLACES_FAVICON_COLUMN)) 
			{
				icon = [NSString stringWithUTF8String:(char *)sqlite3_column_text(dbStatement, PLACES_FAVICON_COLUMN)];
			} 
			else 
			{
				icon = @"";
			}
			
			NSString *client = [NSString stringWithUTF8String:(char *)sqlite3_column_text(dbStatement, PLACES_CLIENT_COLUMN)];
			NSMutableArray *thisTab = [tabs objectForKey:client];
			if (thisTab != nil) 
			{
				[thisTab addObject:[NSArray arrayWithObjects:
											 [NSString stringWithUTF8String:(char *)sqlite3_column_text(dbStatement, PLACES_URL_COLUMN)],
											 [NSString stringWithUTF8String:(char *)sqlite3_column_text(dbStatement, PLACES_TITLE_COLUMN)],
											 icon, nil]];
			} 
			else 
			{
				NSMutableArray *thisTab = [[NSMutableArray alloc] init];
				[thisTab addObject:[NSArray arrayWithObjects:
											 [NSString stringWithUTF8String:(char *)sqlite3_column_text(dbStatement, PLACES_URL_COLUMN)],
											 [NSString stringWithUTF8String:(char *)sqlite3_column_text(dbStatement, PLACES_TITLE_COLUMN)],
											 icon, nil]];
				[tabs setObject:thisTab forKey:client];
				[tabIndex addObject:client];
			}
		}
		sqlite3_finalize(dbStatement);
	} 
}

-(void) loadExistingFavicons
{
	if (favicons == nil)
	{
		sqlite3_stmt *dbStatement;
		const char *faviconQuery = "SELECT * FROM moz_favicons";
		
		favicons = [[NSMutableDictionary alloc] init];
		
		if (sqlite3_prepare_v2(sqlDatabase, faviconQuery, -1, &dbStatement, NULL) == SQLITE_OK) 
		{
			while (sqlite3_step(dbStatement) == SQLITE_ROW) 
			{
				[favicons setObject:[NSString stringWithUTF8String:(char *)sqlite3_column_text(dbStatement, 1)]
										 forKey:[NSString stringWithUTF8String:(char *)sqlite3_column_text(dbStatement, 0)]];
			}
		} 
		sqlite3_finalize(dbStatement);
	}
}

- (void) loadExistingHistory
{
 sqlite3_stmt *dbStatement;
	const char *historyQuery = "SELECT * FROM moz_places WHERE type = 'history'";
	NSString* icon;
	
	history = [[NSMutableArray array] retain];
	
	/* Load existing history */
	if (sqlite3_prepare_v2(sqlDatabase, historyQuery, -1, &dbStatement, NULL) == SQLITE_OK) 
	{
		while (sqlite3_step(dbStatement) == SQLITE_ROW) 
		{
			if ((char *)sqlite3_column_text(dbStatement, PLACES_FAVICON_COLUMN)) 
			{
				icon = [NSString stringWithUTF8String:(char *)sqlite3_column_text(dbStatement, PLACES_FAVICON_COLUMN)];
			} 
			else 
			{
				icon = @"";
			}
			
			[history addObject:[NSArray arrayWithObjects:
													[NSString stringWithUTF8String:(char *)sqlite3_column_text(dbStatement, PLACES_URL_COLUMN)],
													[NSString stringWithUTF8String:(char *)sqlite3_column_text(dbStatement, PLACES_TITLE_COLUMN)],
													icon, nil]];
		}
		sqlite3_finalize(dbStatement);
	} 
}

-(void) loadExistingBookmarks
{
	sqlite3_stmt *dbStatement;
	const char *bookmarkQuery = "SELECT * FROM moz_places WHERE type = 'bookmark'";
	NSString* icon;
	
	bookmarks = [[NSMutableArray array] retain];
	
	//load any bookmarks we can find in the db
	if (sqlite3_prepare_v2(sqlDatabase, bookmarkQuery, -1, &dbStatement, NULL) == SQLITE_OK) 
	{
		while (sqlite3_step(dbStatement) == SQLITE_ROW) 
		{
			if ((char *)sqlite3_column_text(dbStatement, PLACES_FAVICON_COLUMN)) 
			{
				icon = [NSString stringWithUTF8String:(char *)sqlite3_column_text(dbStatement, PLACES_FAVICON_COLUMN)];
			} 
			else 
			{
				icon = @"";
			}
			[bookmarks addObject:[NSArray arrayWithObjects:
														[NSString stringWithUTF8String:(char *)sqlite3_column_text(dbStatement, PLACES_URL_COLUMN)],
														[NSString stringWithUTF8String:(char *)sqlite3_column_text(dbStatement, PLACES_TITLE_COLUMN)],
														icon, nil]];
		}
		sqlite3_finalize(dbStatement);
	} 
}

//////////////////////////////////////////////////////////////////////////////

-(BOOL) setFavicons:(NSString *)JSONObject withID:(NSString*)theID {
	NSString *key;
	NSString *value;
	NSEnumerator *iter;
	
	sqlite3_stmt *stmnt;
	const char *fsql = "INSERT INTO moz_favicons VALUES(?, ?)";
	
	/* Store favicons */
	NSDictionary *resp = [JSONObject JSONValue];
	iter = [resp keyEnumerator];
	while (key = [iter nextObject]) {
		value = [resp valueForKey:key];
		
		if (sqlite3_prepare_v2(sqlDatabase, fsql, -1, &stmnt, NULL) != SQLITE_OK) {
			NSLog(@"Could not prepare favicon statement!");
			return NO;
		}
		
		sqlite3_bind_text(stmnt, 1, [key UTF8String], -1, SQLITE_TRANSIENT);
		sqlite3_bind_text(stmnt, 2, [value UTF8String], -1, SQLITE_TRANSIENT);
		
		if (sqlite3_step(stmnt) != SQLITE_DONE) {
			NSLog(@"%@ unsaved", key);
		}
		sqlite3_finalize(stmnt);		
	}
	
	return YES;
}

///////////////////////////////////////////////////////////////////////
-(BOOL) addBookmarkRecord:(NSString *)json withID:(NSString*)theID {
	@try {
		NSArray *bmkArray = [json JSONValue];
		NSDictionary *bmk = [bmkArray objectAtIndex:0];
			
		if ([[bmk valueForKey:@"type"] isEqualToString:@"bookmark"]) {
			NSString *uri = [bmk valueForKey:@"bmkUri"];
			NSString *title = [bmk valueForKey:@"title"];
				
			NSRange r = NSMakeRange(0, 6);
			if (title && uri && ![[uri substringWithRange:r] isEqualToString:@"place:"]) {
				NSString *favicon = [[NSURL URLWithString:uri] host];
				[bookmarks addObject:[NSArray arrayWithObjects:uri, title, favicon, nil]];
				[self storePlaceInDB:@"bookmark" withURI:uri title:title andFavicon:favicon andID:theID];
				//NSLog(@"Added bookmark %@", uri);
			}
		}
	} @catch (id theException) {
		NSLog(@"threw %@", theException);
		return NO;
	}
	
	return YES;
}



///////////////////////////////////////////////////////////////////////
-(BOOL) removeRecord:(NSString *)theID 
{	
	return [self removePlaceFromDB:theID];
}

// removes all the tabs.  we need to do this before putting the new ones in
- (BOOL) clearTabs
{
  return [self removeTypeFromDB:@"tab"];
}

///////////////////////////////////////////////////////////////////////
//Not sure, but I suspect we will be storing an entire history set, not one at a time.
-(BOOL) addHistoryRecord:(NSString *)json withID:(NSString*)theID {
	// NSLog(@"addHistory %@", json);
	@try {
		NSArray *historyArray = [json JSONValue];
		NSEnumerator *iter = [historyArray objectEnumerator];
		NSDictionary *hist;
		while (hist = [iter nextObject]) {
			NSString *uri = [hist valueForKey:@"histUri"];
			NSString *title = [hist valueForKey:@"title"];
				
			if (title && uri) {
				NSString *favicon = [[NSURL URLWithString:uri] host];
				[history addObject:[NSArray arrayWithObjects:[uri retain], [title retain], [favicon retain], nil]];
				[self storePlaceInDB:@"history" withURI:uri title:title andFavicon:favicon andID:theID ];
			}
		}
	} @catch (id theException) {
		NSLog(@"threw %@", theException);
		return NO;
	}

	return YES;
}


//------------------------------------------------------------
//------------------------------------------------------------

- (BOOL) addTabSet:(NSString *)json withClientID:(NSString*)theID;  //tabIndex computed
{	
	// NSLog(@"addTab %@", json);
	// curiously, the input is an array.

	tabs = [[NSMutableDictionary alloc] init];
	NSArray *data = [json JSONValue];
	NSDictionary *tabRecord = [data objectAtIndex:0];
	NSDictionary *clientDict = [[NSMutableDictionary alloc] init];
	
	@try {
		NSArray *tbs = [tabRecord valueForKey:@"tabs"];
		NSString *client = [tabRecord valueForKey:@"clientName"];
		[clientDict setValue:self forKey:client];
		NSEnumerator *tEnum = [tbs objectEnumerator];
		
		NSDictionary *tab;
		while (tab = [tEnum nextObject]) {
			NSString *uri = [[tab valueForKey:@"urlHistory"] objectAtIndex:0];
			NSString *title = [tab valueForKey:@"title"];
			
			if (title && uri) {
				NSString *favicon = [[NSURL URLWithString:uri] host];
				if (favicon == nil)
					favicon = @"";
				
				NSMutableArray *tb = [tabs objectForKey:client];
				if (tb != nil) {
					[tb addObject:[NSArray arrayWithObjects:uri, title, favicon, nil]];
				} else {
					NSMutableArray *tb = [[NSMutableArray alloc] init];
					[tb addObject:[NSArray arrayWithObjects:uri, title, favicon, nil]];
					[tabs setObject:tb forKey:client];
				}
				[self storePlaceInDB:@"tab" withURI:uri title:title andFavicon:favicon andID:theID maybeClient:client ];
			}
		}
	} @catch (id theException) {
		NSLog(@"Threw %@", theException);
	}
	// TODO leak?
	NSEnumerator *iter = [clientDict keyEnumerator];
	NSString *key;
	tabIndex = [[NSMutableArray alloc] init];
	while (key = [iter nextObject]) {
		[tabIndex addObject:key];
	}
	return YES;
}


///////////////////////////////////////////////////////////////////////
-(void) dealloc {
	sqlite3_close(sqlDatabase);
	[super dealloc];
}

@end
