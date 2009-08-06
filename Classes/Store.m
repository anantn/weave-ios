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
#import "Service.h"
#import "JSON.h"

@implementation Store

@synthesize dataBase, tabs, history, favicons, bookmarks;

-(Store *) initWithDB:(NSString *)db {
	self = [super init];
	
	if (self) {
		BOOL success;
		NSError *error;
		
		tabs = [[NSMutableDictionary alloc] init];
		history = [[NSMutableArray alloc] init];
		bookmarks = [[NSMutableArray alloc] init];
		favicons = [[NSMutableDictionary alloc] init];
		
		NSFileManager *fm = [NSFileManager defaultManager];
		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		NSString *documentsDir = [paths objectAtIndex:0];
		NSString *writablePath = [documentsDir stringByAppendingString:db];
		
		/* DB already exists */
		success = [fm fileExistsAtPath:writablePath];
		if (success) {
			NSLog(@"Existing DB found, using");
			if (sqlite3_open([writablePath UTF8String], &dataBase) == SQLITE_OK) {
				return self;
			} else {
				NSLog(@"Could not open database!");
				return NULL;
			}
		}
		
		/* DB doesn't exist, copy from resource bundle */
		NSString *defaultDB = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:db];
		
		success = [fm copyItemAtPath:defaultDB toPath:writablePath error:&error];
		if (success) {
			if (sqlite3_open([writablePath UTF8String], &dataBase) == SQLITE_OK) {
				return self;
			} else {
				NSLog(@"Could not open database!");
			}
		} else {
			NSLog(@"Could not create database!");
			NSLog([error localizedDescription]);
		}
	}
	
	return NULL;
}

-(BOOL) addUserWithService:(Service *)svc {
	sqlite3_stmt *stmnt;
	const char *sql = "INSERT INTO users ('uid', 'password', 'passphrase') VALUES (?, ?, ?)";

	if (sqlite3_prepare_v2(dataBase, sql, -1, &stmnt, NULL) != SQLITE_OK) {
		NSLog(@"Could not prepare statement!");
		return NO;
	} else {
		sqlite3_bind_text(stmnt, 1, [[svc username] UTF8String], -1, SQLITE_TRANSIENT);
		sqlite3_bind_text(stmnt, 2, [[svc password] UTF8String], -1, SQLITE_TRANSIENT);
		sqlite3_bind_text(stmnt, 3, [[svc passphrase] UTF8String], -1, SQLITE_TRANSIENT);
		
		if (sqlite3_step(stmnt) != SQLITE_DONE) {
			NSLog(@"Could not save user to DB!");
			sqlite3_finalize(stmnt);
			return NO;
		}
	}
	
	sqlite3_finalize(stmnt);
	return YES;
}

-(double) getSyncTimeForUser:(NSString *)user {
	double time;
	sqlite3_stmt *stmnt;
	const char *sql = "SELECT last_sync FROM users WHERE uid = ?";

	if (sqlite3_prepare_v2(dataBase, sql, -1, &stmnt, NULL) != SQLITE_OK) {
		NSLog(@"Could not prepare statement (load time)!");
		return 0;
	} else {
		sqlite3_bind_text(stmnt, 1, [user UTF8String], -1, SQLITE_TRANSIENT);
		if (sqlite3_step(stmnt) == SQLITE_ROW) {
			time = sqlite3_column_double(stmnt, 0);
		} else {
			NSLog(@"Could not execute SQL to load sync time!");
			sqlite3_finalize(stmnt);
			return 0;
		}		
	}
	
	return time;
}

-(BOOL) setSyncTimeForUser:(NSString *)user {
	sqlite3_stmt *stmnt;
	const char *sql = "UPDATE users SET last_sync = ? WHERE uid = ?";
	
	if (sqlite3_prepare_v2(dataBase, sql, -1, &stmnt, NULL) != SQLITE_OK) {
		NSLog(@"Could not prepare statement (set time)!");
		return NO;
	} else {
		sqlite3_bind_double(stmnt, 1, [[NSDate date] timeIntervalSince1970]);
		sqlite3_bind_text(stmnt, 2, [user UTF8String], -1, SQLITE_TRANSIENT);
		if (sqlite3_step(stmnt) != SQLITE_DONE) {
			NSLog(@"Could not execute SQL to update time for user!");
			sqlite3_finalize(stmnt);
			return NO;
		}
	}
	
	sqlite3_finalize(stmnt);
	NSLog(@"Sync time set for user %@", user);
	return YES;	
}

-(BOOL) loadUserToService:(Service *)svc {
	NSString *usr;
	NSString *pwd;
	NSString *pph;
	NSString *icon;
	
	/* WTF: Close & open DB to get results? */
	sqlite3_close(dataBase);
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDir = [paths objectAtIndex:0];
	NSString *writablePath = [documentsDir stringByAppendingString:@"/store.sq3"];
	if (!sqlite3_open([writablePath UTF8String], &dataBase) == SQLITE_OK) {
		NSLog(@"Could not open database!");
		return NO;
	}
	
	sqlite3_stmt *stmnt;
	const char *sql = "SELECT * FROM users LIMIT 1";
	const char *hSql = "SELECT * FROM moz_places WHERE type = 'history'";
	const char *bSql = "SELECT * FROM moz_places WHERE type = 'bookmark'";
	const char *tSql = "SELECT * FROM moz_places WHERE type = 'tab'";
	const char *iSql = "SELECT * FROM moz_favicons";
	
	if (sqlite3_prepare_v2(dataBase, sql, -1, &stmnt, NULL) == SQLITE_OK) {
		if (sqlite3_step(stmnt) == SQLITE_ROW) {
			usr = [NSString stringWithUTF8String:(char *)sqlite3_column_text(stmnt, 1)];
			pwd = [NSString stringWithUTF8String:(char *)sqlite3_column_text(stmnt, 2)];
			pph = [NSString stringWithUTF8String:(char *)sqlite3_column_text(stmnt, 3)];
			
			[svc setUsername:usr];
			[svc setPassword:pwd];
			[svc setPassphrase:pph];
		} else {
			NSLog(@"Could not execute SQL to LOAD!");
			sqlite3_finalize(stmnt);
			return NO;
		}
	} else {
		NSLog(@"Could not prepare SQL to LOAD!");
		return NO;
	}
	sqlite3_finalize(stmnt);
	
	/* Load existing bookmarks */
	if (sqlite3_prepare_v2(dataBase, bSql, -1, &stmnt, NULL) == SQLITE_OK) {
		while (sqlite3_step(stmnt) == SQLITE_ROW) {
			if ((char *)sqlite3_column_text(stmnt, 5)) {
				icon = [NSString stringWithUTF8String:(char *)sqlite3_column_text(stmnt, 5)];
			} else {
				icon = @"";
			}
			[bookmarks addObject:[NSArray arrayWithObjects:
								  [NSString stringWithUTF8String:(char *)sqlite3_column_text(stmnt, 2)],
								  [NSString stringWithUTF8String:(char *)sqlite3_column_text(stmnt, 3)],
								  icon, nil]];
		}
	} else {
		NSLog(@"Could not prepare SQL to load bookmark!");
		return NO;
	}
	sqlite3_finalize(stmnt);
	
	/* Load existing history */
	if (sqlite3_prepare_v2(dataBase, hSql, -1, &stmnt, NULL) == SQLITE_OK) {
		while (sqlite3_step(stmnt) == SQLITE_ROW) {
			if ((char *)sqlite3_column_text(stmnt, 5)) {
				icon = [NSString stringWithUTF8String:(char *)sqlite3_column_text(stmnt, 5)];
			} else {
				icon = @"";
			}
			
			[history addObject:[NSArray arrayWithObjects:
								  [NSString stringWithUTF8String:(char *)sqlite3_column_text(stmnt, 2)],
								  [NSString stringWithUTF8String:(char *)sqlite3_column_text(stmnt, 3)],
								  icon, nil]];
		}
	} else {
		NSLog(@"Could not prepare SQL to load history!");
		return NO;
	}
	sqlite3_finalize(stmnt);
	
	/* Load existing tabs */
	if (sqlite3_prepare_v2(dataBase, tSql, -1, &stmnt, NULL) == SQLITE_OK) {
		while (sqlite3_step(stmnt) == SQLITE_ROW) {
			if ((char *)sqlite3_column_text(stmnt, 5)) {
				icon = [NSString stringWithUTF8String:(char *)sqlite3_column_text(stmnt, 5)];
			} else {
				icon = @"";
			}
			
			NSString *client = [NSString stringWithUTF8String:(char *)sqlite3_column_text(stmnt, 4)];
			NSMutableArray *tb = [tabs objectForKey:client];
			if (tb != nil) {
				[tb addObject:[NSArray arrayWithObjects:
							   [NSString stringWithUTF8String:(char *)sqlite3_column_text(stmnt, 2)],
								[NSString stringWithUTF8String:(char *)sqlite3_column_text(stmnt, 3)],
								icon, nil]];
			} else {
				NSMutableArray *tb = [[NSMutableArray alloc] init];
				[tb addObject:[NSArray arrayWithObjects:
							   [NSString stringWithUTF8String:(char *)sqlite3_column_text(stmnt, 2)],
							   [NSString stringWithUTF8String:(char *)sqlite3_column_text(stmnt, 3)],
							   icon, nil]];
				[tabs setObject:tb forKey:client];
			}
		}
	} else {
		NSLog(@"Could not prepare SQL to load tabs!");
		return NO;
	}
	sqlite3_finalize(stmnt);
	
	/* Load favicons */
	if (sqlite3_prepare_v2(dataBase, iSql, -1, &stmnt, NULL) == SQLITE_OK) {
		while (sqlite3_step(stmnt) == SQLITE_ROW) {
			[favicons setObject:[NSString stringWithUTF8String:(char *)sqlite3_column_text(stmnt, 1)]
						 forKey:[NSString stringWithUTF8String:(char *)sqlite3_column_text(stmnt, 0)]];
		}
	} else {
		NSLog(@"Could not prepare SQL to load favicons!");
		return NO;
	}
	sqlite3_finalize(stmnt);
	
	NSLog(@"Store loaded %d history items, %d bookmarks, %d tabs and %d favicons",
		  [history count], [bookmarks count], [tabs count], [favicons count]);
	return YES;
}

-(int) getUsers {
	int cnt = 0;
	sqlite3_stmt *stmnt;
	const char *sql = "SELECT COUNT(*) FROM users";
	
	if (sqlite3_prepare_v2(dataBase, sql, -1, &stmnt, NULL) == SQLITE_OK) {
		if (sqlite3_step(stmnt) == SQLITE_ROW) {
			cnt = sqlite3_column_int(stmnt, 0);
		}
	}
	
	sqlite3_finalize(stmnt);
	return cnt;
}

-(BOOL) addPlace:(NSString *)type withURI:(NSString *)uri title:(NSString *)title andFavicon:(NSString *)favicon maybeClient:(NSString *)client {
	const char *sql;
	sqlite3_stmt *stmnt;
	
	if ([type isEqualToString:@"bookmark"])
		sql = "INSERT INTO moz_places ('type', 'url', 'title', 'favicon') VALUES ('bookmark', ?, ?, ?)";
	else if ([type isEqualToString:@"history"])
		sql = "INSERT INTO moz_places ('type', 'url', 'title', 'favicon') VALUES ('history', ?, ?, ?)";
	else {
		if (client != nil)
			sql = "INSERT INTO moz_places ('type', 'url', 'title', 'client', 'favicon') VALUES ('tab', ?, ?, ?, ?)";
		else
			return NO;
	}
	
	if (sqlite3_prepare_v2(dataBase, sql, -1, &stmnt, NULL) != SQLITE_OK) {
		NSLog(@"Could not prepare statement!");
		return NO;
	} else {
		sqlite3_bind_text(stmnt, 1, [uri UTF8String], -1, SQLITE_TRANSIENT);
		sqlite3_bind_text(stmnt, 2, [title UTF8String], -1, SQLITE_TRANSIENT);
		if ([type isEqualToString:@"tab"]) {
			sqlite3_bind_text(stmnt, 3, [client UTF8String], -1, SQLITE_TRANSIENT);
			sqlite3_bind_text(stmnt, 4, [favicon UTF8String], -1, SQLITE_TRANSIENT);
		} else {
			sqlite3_bind_text(stmnt, 3, [favicon UTF8String], -1, SQLITE_TRANSIENT);
		}
		
		if (sqlite3_step(stmnt) != SQLITE_DONE) {
			NSLog(@"Could not save place to DB!");
			sqlite3_finalize(stmnt);
			return NO;
		}
	}
	sqlite3_finalize(stmnt);
	return YES;
}

-(BOOL) addPlace:(NSString *)type withURI:(NSString *)uri title:(NSString *)title andFavicon:(NSString *)favicon {
	return [self addPlace:type withURI:uri title:title andFavicon:favicon maybeClient:nil];
}

-(BOOL) addFavicons:(NSString *)json {
	NSString *key;
	NSString *value;
	NSEnumerator *iter;
	
	sqlite3_stmt *stmnt;
	const char *fsql = "INSERT INTO moz_favicons VALUES(?, ?)";
	
	/* Store favicons */
	NSDictionary *resp = [json JSONValue];
	iter = [resp keyEnumerator];
	while (key = [iter nextObject]) {
		value = [resp valueForKey:key];
		
		if (sqlite3_prepare_v2(dataBase, fsql, -1, &stmnt, NULL) != SQLITE_OK) {
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

-(BOOL) addBookmarkRecord:(NSString *)json {
	@try {
		NSDictionary *obj = [json JSONValue];
		NSDictionary *payload = [obj valueForKey:@"payload"];
		NSString *cipher = [payload valueForKey:@"ciphertext"];
		NSArray *item = [cipher JSONValue];
		NSDictionary *bmk = [item objectAtIndex:0];
			
		if ([[bmk valueForKey:@"type"] isEqualToString:@"bookmark"]) {
			NSString *uri = [bmk valueForKey:@"bmkUri"];
			NSString *title = [bmk valueForKey:@"title"];
				
			NSRange r = NSMakeRange(0, 6);
			if (title && uri && ![[uri substringWithRange:r] isEqualToString:@"place:"]) {
				NSString *favicon = [[NSURL URLWithString:uri] host];
				[bookmarks addObject:[NSArray arrayWithObjects:uri, title, favicon, nil]];
				[self addPlace:@"bookmark" withURI:uri title:title andFavicon:favicon];
			}
		}
	} @catch (id theException) {
		NSLog(@"threw %@", theException);
		return NO;
	}
	
	return YES;
}

-(BOOL) addHistoryRecord:(NSString *)json {
	@try {
		NSDictionary *obj = [json JSONValue];
		NSDictionary *payload = [obj valueForKey:@"payload"];
		NSString *cipher = [payload valueForKey:@"ciphertext"];
		NSArray *item = [cipher JSONValue];
		NSDictionary *hist = [item objectAtIndex:0];
			
		NSString *uri = [hist valueForKey:@"histUri"];
		NSString *title = [hist valueForKey:@"title"];
			
		if (title && uri) {
			NSString *favicon = [[NSURL URLWithString:uri] host];
			[history addObject:[NSArray arrayWithObjects:uri, title, favicon, nil]];
			[self addPlace:@"history" withURI:uri title:title andFavicon:favicon];
		}
	} @catch (id theException) {
		NSLog(@"threw %@", theException);
		return NO;
	}

	return YES;
}

-(BOOL) addTabs:(NSString *)json {	
	NSDictionary *obj;
	NSDictionary *tab;
	NSEnumerator *iter = [[json JSONValue] objectEnumerator];
	
	while (obj = [iter nextObject]) {
		@try {
			NSDictionary *payload = [obj valueForKey:@"payload"];
			NSString *cipher = [payload valueForKey:@"ciphertext"];

			NSArray *tbs = [[[cipher JSONValue] objectAtIndex:0] valueForKey:@"tabs"];
			NSString *client = [[[cipher JSONValue] objectAtIndex:0] valueForKey:@"clientName"];
			NSEnumerator *tEnum = [tbs objectEnumerator];
			
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
					[self addPlace:@"tab" withURI:uri title:title andFavicon:favicon maybeClient:client];
				}
			}
		} @catch (id theException) {
			NSLog(@"Threw %@", theException);
		}
	}
	
	return YES;
}
	
-(void) dealloc {
	sqlite3_close(dataBase);
	[super dealloc];
}

@end
