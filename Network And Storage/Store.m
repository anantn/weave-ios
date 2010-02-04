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
#import "Fetcher.h"
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
- (void) loadTabsFromDB;
- (void) loadHistoryFromDB;
- (void) loadBookmarksFromDB;
- (void) loadFaviconsFromDB;
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

+ (void) deleteStore
{
  [_gStore release];
  _gStore = nil;
  
  NSFileManager *fileManager = [NSFileManager defaultManager];
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString *documentsDir = [paths objectAtIndex:0];
  NSString *databasePath = [documentsDir stringByAppendingString:@"/store.sq3"];
  
  NSError* err;
  [fileManager removeItemAtPath:databasePath error:&err];
  if (err != nil)
    NSLog(@"database delete failed: %@", err);
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
		
		NSFileManager *fileManager = [NSFileManager defaultManager];
		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		NSString *documentsDir = [paths objectAtIndex:0];
		NSString *databasePath = [documentsDir stringByAppendingString:filePath];
		
		/* DB already exists */
		success = [fileManager fileExistsAtPath:databasePath];
		if (success) 
		{
			NSLog(@"Existing DB found, using");
			if (sqlite3_open([databasePath UTF8String], &sqlDatabase) == SQLITE_OK) 
			{
				[self loadUserInfo];
				[self loadTabsFromDB];
				[self loadHistoryFromDB];
				[self loadBookmarksFromDB];
				[self loadFaviconsFromDB];
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
		
		success = [fileManager copyItemAtPath:defaultDB toPath:databasePath error:&error];
		if (success) {
			if (sqlite3_open([databasePath UTF8String], &sqlDatabase) == SQLITE_OK) {
				tabs = [[NSMutableArray array] retain];
				history = [[NSMutableArray array] retain];
				bookmarks = [[NSMutableArray array] retain];
				favicons = [[NSMutableDictionary dictionary] retain];
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

- (NSArray*)  getTabs
{
	return tabs;
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

-(void)loadTabsFromDB
{
  //ok, for easier use with the UI code, we're going to load the tabs into a structure with the following shape:
  // * Array, one slot for each client, which is a:
  //   * Dictionary, containing:
  //     * String (the client guid) with key 'guid'
  //     * String (the client name) with key 'client'
  //     * Array (the tabs) with key 'tabs', containing:
  //       * Dictionary (the tab properties) containing:
  //         * String (the title) with key 'title'
  //         * String (the uri) with key 'uri'
  //         * String (the icon) with key 'icon'
  
	sqlite3_stmt *dbStatement;
	const char *tabQuery = "SELECT * FROM moz_places WHERE type = 'tab'";
	NSString* icon;
		
  //ok, this is a temporary dictionary to build our data structure.
  NSMutableDictionary* temporaryTabIndex = [NSMutableDictionary dictionary];
  
	if (sqlite3_prepare_v2(sqlDatabase, tabQuery, -1, &dbStatement, NULL) == SQLITE_OK) 
	{
		while (sqlite3_step(dbStatement) == SQLITE_ROW) 
		{
			if ((char *)sqlite3_column_text(dbStatement, PLACES_FAVICON_COLUMN)) {
				icon = [NSString stringWithUTF8String:(char *)sqlite3_column_text(dbStatement, PLACES_FAVICON_COLUMN)];
			} else {
        icon = @"";
      }
      
			
      NSString *guid = [NSString stringWithUTF8String:(char *)sqlite3_column_text(dbStatement, PLACES_GUID_COLUMN)];
			NSString *client = [NSString stringWithUTF8String:(char *)sqlite3_column_text(dbStatement, PLACES_CLIENT_COLUMN)];
      
      NSMutableDictionary* thisClient = [temporaryTabIndex objectForKey:guid];
      
			if (thisClient == nil)
			{
				thisClient = [NSMutableDictionary dictionary];
        [thisClient setObject:guid forKey:@"guid"];
        [thisClient setObject:client forKey:@"client"];
        [thisClient setObject:[NSMutableArray array] forKey:@"tabs"];
        [temporaryTabIndex setObject:thisClient forKey:guid];
			}
      
      [[thisClient objectForKey:@"tabs"] addObject: [NSDictionary dictionaryWithObjectsAndKeys:
                           [NSString stringWithUTF8String:(char *)sqlite3_column_text(dbStatement, PLACES_TITLE_COLUMN)], @"title",
                           [NSString stringWithUTF8String:(char *)sqlite3_column_text(dbStatement, PLACES_URL_COLUMN)], @"uri",
                           icon, @"icon",
                           nil]];
      
      //NSLog(@"tab: %@", thisClient);
      
		}
		sqlite3_finalize(dbStatement);
    
    NSMutableArray* newTabs = [[NSMutableArray array] retain];
    
    id key;
    NSEnumerator *enumerator = [temporaryTabIndex keyEnumerator];
    
    while ((key = [enumerator nextObject])) {
      [newTabs addObject:[temporaryTabIndex objectForKey:key]];
    }
    
    NSMutableArray* temp = tabs;
    tabs = newTabs;
    [temp release];

	} 
}

- (UIImage *)make32x32imageFrom:(UIImage *)oldImage 
{ 
  
  CGSize imageSize = CGSizeMake(32, 32);
  
  void *data = malloc(imageSize.width * imageSize.height * 4);
  
  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
  CGContextRef ctx = CGBitmapContextCreate(data, 
                                           imageSize.width, 
                                           imageSize.height, 8, 
                                           imageSize.width*4, 
                                           colorSpace, 
                                           kCGImageAlphaPremultipliedLast
                                           );
  CGColorSpaceRelease(colorSpace);
  
  float white[4] = {1, 1, 1, 1};
  CGContextSetFillColor(ctx, white);

  // now actually draw the image into the larger frame
  CGRect newFrame = CGRectMake(0, 0, 32, 32);
  CGContextFillRect(ctx, newFrame);
  CGContextDrawImage(ctx, newFrame, [oldImage CGImage]);

  
  CGImageRef image = CGBitmapContextCreateImage(ctx);
  UIImage *returnImage = [UIImage imageWithCGImage:image];
  CGImageRelease(image);
  CGContextRelease(ctx);
  free(data);
  
  return returnImage;
}



-(void) loadFaviconsFromDB
{
  sqlite3_stmt *dbStatement;
  const char *faviconQuery = "SELECT * FROM moz_favicons";
  
  NSMutableDictionary* newFavicons = [[NSMutableDictionary dictionary] retain];
  
  //default
  [newFavicons setObject:[UIImage imageNamed:@"blankfavicon.ico"] forKey:@"blankfavicon.ico"];

  if (sqlite3_prepare_v2(sqlDatabase, faviconQuery, -1, &dbStatement, NULL) == SQLITE_OK) 
  {
    while (sqlite3_step(dbStatement) == SQLITE_ROW) 
    {
      NSString* imgStr = [NSString stringWithUTF8String:(char *)sqlite3_column_text(dbStatement, 1)];
      NSData* imgData = [[[NSData alloc] initWithBase64EncodedString:imgStr] autorelease];  
      UIImage* img = [UIImage imageWithData:imgData];
      if (img)
      {
        //resize it to 32x32 if it isn't
        if (img.size.width != 32)
        {
          CGSize size32;
          size32.width = 32;
          size32.height = 32;
          UIImage* scaledImg = [self make32x32imageFrom:img ];
          //[img release];
          img = scaledImg;
        }
        
        [newFavicons setObject:img forKey:[NSString stringWithUTF8String:(char *)sqlite3_column_text(dbStatement, 0)]];
      }
    }
  } 
  NSMutableDictionary* temp = favicons;
  favicons = newFavicons;
  [temp release];

  sqlite3_finalize(dbStatement);
}

- (void) loadHistoryFromDB
{
  sqlite3_stmt *dbStatement;
	const char *historyQuery = "SELECT * FROM moz_places WHERE type = 'history'";
	NSString* icon;
	
	NSMutableArray* newHistory = [[NSMutableArray array] retain];
	
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
			
      [newHistory addObject: [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSString stringWithUTF8String:(char *)sqlite3_column_text(dbStatement, PLACES_TITLE_COLUMN)], @"title",
                             [NSString stringWithUTF8String:(char *)sqlite3_column_text(dbStatement, PLACES_URL_COLUMN)], @"uri",
                             icon, @"icon",
                             nil]];
		}
		sqlite3_finalize(dbStatement);
	} 
  NSMutableArray* temp = history;
  history = newHistory;
  [temp release];

}



static int compareBookmarks(id left,  id right, void* ctx)
{
  return [[left objectForKey:@"title"] localizedCompare: [right objectForKey:@"title"]]; //ascending
}


-(void) loadBookmarksFromDB
{
	sqlite3_stmt *dbStatement;
	const char *bookmarkQuery = "SELECT * FROM moz_places WHERE type = 'bookmark'";
	NSString* icon;
	
	NSMutableArray* newBookmarks = [[NSMutableArray array] retain];
	
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
      
      [newBookmarks addObject: [NSDictionary dictionaryWithObjectsAndKeys:
                                                     [NSString stringWithUTF8String:(char *)sqlite3_column_text(dbStatement, PLACES_TITLE_COLUMN)], @"title",
                                                     [NSString stringWithUTF8String:(char *)sqlite3_column_text(dbStatement, PLACES_URL_COLUMN)], @"uri",
                                                     icon, @"icon",
                                                     nil]];
      }
		sqlite3_finalize(dbStatement);
	} 
  NSMutableArray* temp = bookmarks;
  bookmarks = newBookmarks;
  [temp release];

  [bookmarks sortUsingFunction:compareBookmarks context:nil];

}


//computes and returns the path to the favicon for a given url.  for now, it's the old path http://<host>/favicon.ico
- (NSString*) faviconPathForURL:(NSString*)url
{
  NSMutableString* favpath = [NSMutableString string];
  NSString* host = [[NSURL URLWithString:url] host];
  if (host && [host length] > 0)
      [favpath appendFormat:@"http://%@/favicon.ico",host , nil];
  return favpath;
}



//////////////////////////////////////////////////////////////////////////////
//this inserts a single [url, icon] pair into the database, which can be called by anyone
- (BOOL) cacheFavicon:(NSString*)icon forURL:(NSString*)url
{
  sqlite3_stmt *stmnt;
	const char *fsql = "INSERT INTO moz_favicons VALUES(?, ?)";
  
  if (sqlite3_prepare_v2(sqlDatabase, fsql, -1, &stmnt, NULL) != SQLITE_OK) {
    NSLog(@"Could not prepare favicon statement!");
    return NO;
  }
  
  sqlite3_bind_text(stmnt, 1, [url UTF8String], -1, SQLITE_TRANSIENT);
  sqlite3_bind_text(stmnt, 2, [icon UTF8String], -1, SQLITE_TRANSIENT);
  
  if (sqlite3_step(stmnt) != SQLITE_DONE) {
    NSLog(@"%@ unsaved", url);
    return NO;
  }
  
  sqlite3_finalize(stmnt);		
  return YES;
}


- (void) refreshFavicons
{
  sqlite3_stmt *dbStatement;
  //this query should give us all favicon paths that are not already in the favicon table
	const char *faviconQuery = "SELECT DISTINCT favicon FROM moz_places EXCEPT SELECT url FROM moz_favicons";
		
	if (sqlite3_prepare_v2(sqlDatabase, faviconQuery, -1, &dbStatement, NULL) == SQLITE_OK) 
	{
		while (sqlite3_step(dbStatement) == SQLITE_ROW) 
		{
      //now go get the icon, and save it in the db
      char* column = (char*)sqlite3_column_text(dbStatement, 0);
      if (column == nil) continue;
      
			NSString* url = [NSString stringWithCString:column encoding:NSUTF8StringEncoding];
      NSData* iconbytes = [Fetcher getPublicURL:url];
      
      NSString* iconstring;
      if (iconbytes && [iconbytes length] > 0) {
         iconstring = [iconbytes base64Encoding];
      }
      else {
        iconstring = @"";
      }

      //NSLog(@"url: %@   icon: %@", url, iconstring);
      //now store the iconstring in the moz_favicons table, with the specified url.
      // we're storing empty strings for the ones we couldn't get, so we don't keep trying to look them up
      [self cacheFavicon:iconstring forURL:url];

		}
		sqlite3_finalize(dbStatement);
	} 
  
  [self loadFaviconsFromDB];
}




//this one unwraps a JSON list and walks the [url, icon] pairs inside, inserting each into the database
// this is called if we use the favicon proxy
- (BOOL) cacheFaviconsFromJSON:(NSString *)JSONObject withID:(NSString*)theID
{
	NSString *key;
	NSString *value;
	NSEnumerator *iter;
	
	
	/* Store favicons */
	NSDictionary *resp = [JSONObject JSONValue];
	iter = [resp keyEnumerator];
	while (key = [iter nextObject])
  {
		value = [resp valueForKey:key];
		[self cacheFavicon:value forURL:key];
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
				NSString *favicon = [self faviconPathForURL:uri];
				[self storePlaceInDB:@"bookmark" withURI:uri title:title andFavicon:favicon andID:theID];
				//NSLog(@"Added bookmark %@", uri);
			}
		}
	} @catch (id theException) {
		NSLog(@"threw %@", theException);
		return NO;
	}
	
  [self loadBookmarksFromDB];

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
-(BOOL) addHistorySet:(NSString *)json withClientID:(NSString*)theID {
	// NSLog(@"addHistory %@", json);
	@try {
		NSArray *historyArray = [json JSONValue];
		NSEnumerator *iter = [historyArray objectEnumerator];
		NSDictionary *hist;
		while (hist = [iter nextObject]) {
			NSString *uri = [hist valueForKey:@"histUri"];
			NSString *title = [hist valueForKey:@"title"];
				
			if (title && uri) {
				NSString *favicon = [self faviconPathForURL:uri];
				[self storePlaceInDB:@"history" withURI:uri title:title andFavicon:favicon andID:theID ];
			}
		}
	} @catch (id theException) {
		NSLog(@"threw %@", theException);
		return NO;
	}

  [self loadHistoryFromDB];

	return YES;
}


//------------------------------------------------------------
//------------------------------------------------------------

- (BOOL) addTabSet:(NSArray *)tabSetDict withClientID:(NSString*)theID;  //tabIndex computed
{	
	NSDictionary *tabRecord = [tabSetDict objectAtIndex:0];
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
				NSString *favicon = [self faviconPathForURL:uri];
        [self storePlaceInDB:@"tab" withURI:uri title:title andFavicon:favicon andID:theID maybeClient:client];
			}
		}
	} @catch (id theException) {
		NSLog(@"Threw %@", theException);
	}

	return YES;
}


- (BOOL) installTabSetDictionary:(NSDictionary *)tabSetDict
{
  // Use a transaction to put them in the database safely
  [self beginTransaction];

  // First, delete all the existing tabs.
  [self clearTabs];  

  // Second, insert all the new tabs 
  for (NSString* anID in [tabSetDict allKeys]) {
    [self addTabSet:[tabSetDict objectForKey:anID] withClientID:anID];
  }
  [self endTransaction];
  
  [self loadTabsFromDB];
  return YES;
}


///////////////////////////////////////////////////////////////////////
-(void) dealloc {
	sqlite3_close(sqlDatabase);
  [tabs release];
  tabs = nil;
  [bookmarks release];
  bookmarks = nil;
  [history release];
  history = nil;
  [favicons release];
  favicons = nil;
  [username release];
  username = nil;
  [password release];
  password = nil;
    
	[super dealloc];
}

@end
