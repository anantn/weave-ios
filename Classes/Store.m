//
//  Store.m
//  Weave
//
//  Created by Anant Narayanan on 6/4/09.
//  Copyright 2009 Mozilla Corporation. All rights reserved.
//

#import "Store.h"
#import "Utility.h"
#import "Service.h"
#import <JSON/JSON.h>

@implementation Store

@synthesize dataBase, bmkUris, bmkTitles, histUris, histTitles, tabUris, tabTitles;

-(Store *) initWithDB:(NSString *)db {
	self = [super init];
	
	if (self) {
		BOOL success;
		NSError *error;
		
		histUris = [[NSMutableArray alloc] init];
		histTitles = [[NSMutableArray alloc] init];
		bmkUris = [[NSMutableArray alloc] init];
		bmkTitles = [[NSMutableArray alloc] init];
		tabUris = [[NSMutableArray alloc] init];
		tabTitles = [[NSMutableArray alloc] init];
		
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

-(BOOL) loadUserToService:(Service *)svc {
	NSString *usr;
	NSString *pwd;
	NSString *pph;
	NSString *base;
	
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
	
	if (sqlite3_prepare_v2(dataBase, sql, -1, &stmnt, NULL) == SQLITE_OK) {
		if (sqlite3_step(stmnt) == SQLITE_ROW) {
			usr = [NSString stringWithUTF8String:(char *)sqlite3_column_text(stmnt, 1)];
			pwd = [NSString stringWithUTF8String:(char *)sqlite3_column_text(stmnt, 2)];
			pph = [NSString stringWithUTF8String:(char *)sqlite3_column_text(stmnt, 3)];
			base = [NSString stringWithUTF8String:(char *)sqlite3_column_text(stmnt, 4)];
			
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
	
	/* Load existing bookmarks, history and tabs */
	if (sqlite3_prepare_v2(dataBase, bSql, -1, &stmnt, NULL) == SQLITE_OK) {
		while (sqlite3_step(stmnt) == SQLITE_ROW) {
			[bmkUris addObject:[NSString stringWithUTF8String:(char *)sqlite3_column_text(stmnt, 2)]];
			[bmkTitles addObject:[NSString stringWithUTF8String:(char *)sqlite3_column_text(stmnt, 3)]];
		}
	} else {
		NSLog(@"Could not prepare SQL to load bookmark!");
		return NO;
	}
	sqlite3_finalize(stmnt);
	
	if (sqlite3_prepare_v2(dataBase, hSql, -1, &stmnt, NULL) == SQLITE_OK) {
		while (sqlite3_step(stmnt) == SQLITE_ROW) {
			[histUris addObject:[NSString stringWithUTF8String:(char *)sqlite3_column_text(stmnt, 2)]];
			[histTitles addObject:[NSString stringWithUTF8String:(char *)sqlite3_column_text(stmnt, 3)]];
		}
	} else {
		NSLog(@"Could not prepare SQL to load history!");
		return NO;
	}
	sqlite3_finalize(stmnt);
	
	if (sqlite3_prepare_v2(dataBase, tSql, -1, &stmnt, NULL) == SQLITE_OK) {
		while (sqlite3_step(stmnt) == SQLITE_ROW) {
			[tabUris addObject:[NSString stringWithUTF8String:(char *)sqlite3_column_text(stmnt, 2)]];
			[tabTitles addObject:[NSString stringWithUTF8String:(char *)sqlite3_column_text(stmnt, 3)]];
		}
	} else {
		NSLog(@"Could not prepare SQL to load tabs!");
		return NO;
	}
	sqlite3_finalize(stmnt);
	
	NSLog(@"Store loaded %d history items, %d bookmarks, and %d tabs", [histUris count], [bmkUris count], [tabUris count]);
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

-(BOOL) addPlace:(NSString *)type withURI:(NSString *)uri andTitle:(NSString *)title {
	const char *sql;
	sqlite3_stmt *stmnt;
	
	if ([type isEqualToString:@"bookmark"])
		sql = "INSERT INTO moz_places ('type', 'url', 'title') VALUES ('bookmark', ?, ?)";
	else if ([type isEqualToString:@"history"])
		sql = "INSERT INTO moz_places ('type', 'url', 'title') VALUES ('history', ?, ?)";
	else
		sql = "INSERT INTO moz_places ('type', 'url', 'title') VALUES ('tab', ?, ?)";
	
	if (sqlite3_prepare_v2(dataBase, sql, -1, &stmnt, NULL) != SQLITE_OK) {
		NSLog(@"Could not prepare statement!");
		return NO;
	} else {
		sqlite3_bind_text(stmnt, 1, [uri UTF8String], -1, SQLITE_TRANSIENT);
		sqlite3_bind_text(stmnt, 2, [title UTF8String], -1, SQLITE_TRANSIENT);
		
		if (sqlite3_step(stmnt) != SQLITE_DONE) {
			NSLog(@"Could not save place to DB!");
			sqlite3_finalize(stmnt);
			return NO;
		}
	}
	sqlite3_finalize(stmnt);
	return YES;
}

-(BOOL) addBookmarks:(NSString *)json {
	NSArray *items = [[json JSONValue] valueForKey:@"contents"];
	NSEnumerator *iter = [items objectEnumerator];
	
	NSDictionary *obj;
	while (obj = [iter nextObject]) {
		NSDictionary *payload = [obj valueForKey:@"payload"];
		@try {
			NSString *cipher = [payload valueForKey:@"ciphertext"];
			NSArray *item = [cipher JSONValue];
			NSDictionary *bmk = [item objectAtIndex:0];
			
			if ([[bmk valueForKey:@"type"] isEqualToString:@"bookmark"]) {
				NSString *uri = [bmk valueForKey:@"bmkUri"];
				NSString *title = [bmk valueForKey:@"title"];
				
				NSRange r = NSMakeRange(0, 6);
				if (title && uri && ![[uri substringWithRange:r] isEqualToString:@"place:"]) {
					[bmkUris addObject:uri];
					[bmkTitles addObject:title];
					[self addPlace:@"bookmark" withURI:uri andTitle:title];
				}
			}
		} @catch (id theException) {
			NSLog(@"%@ threw %@", payload, theException);
		}
	}
	
	return YES;
}

-(BOOL) addHistory:(NSString *)json {
	NSArray *items = [[json JSONValue] valueForKey:@"contents"];
	NSEnumerator *iter = [items objectEnumerator];
	
	NSDictionary *obj;
	while (obj = [iter nextObject]) {
		NSDictionary *payload = [obj valueForKey:@"payload"];
		@try {
			NSString *cipher = [payload valueForKey:@"ciphertext"];
			NSArray *item = [cipher JSONValue];
			NSDictionary *hist = [item objectAtIndex:0];
			
			NSString *uri = [hist valueForKey:@"histUri"];
			NSString *title = [hist valueForKey:@"title"];
			
			if (title && uri) {
				[histUris addObject:uri];
				[histTitles addObject:title];
				[self addPlace:@"history" withURI:uri andTitle:title];
			}
		} @catch (id theException) {
			NSLog(@"%@ threw %@", payload, theException);
		}
	}

	return YES;
}

-(BOOL) addTabs:(NSString *)json {
	NSArray *items = [[json JSONValue] valueForKey:@"contents"];
	NSEnumerator *iter = [items objectEnumerator];
	
	NSDictionary *obj;
	NSDictionary *tab;
	
	while (obj = [iter nextObject]) {
		@try {
			NSDictionary *payload = [obj valueForKey:@"payload"];
			NSString *cipher = [payload valueForKey:@"ciphertext"];
			NSArray *tabs = [[[cipher JSONValue] objectAtIndex:0] valueForKey:@"tabs"];
			NSEnumerator *tEnum = [tabs objectEnumerator];
			
			while (tab = [tEnum nextObject]) {
				NSString *uri = [[tab valueForKey:@"urlHistory"] objectAtIndex:0];
				NSString *title = [tab valueForKey:@"title"];
				
				if (title && uri) {
					[self addPlace:@"tab" withURI:uri andTitle:title];
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
