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

@synthesize dataBase, bmkUris, bmkTitles, histUris, histTitles;

-(Store *) initWithDB:(NSString *)db {
	self = [super init];
	
	if (self) {
		BOOL success;
		NSError *error;
		
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
	const char *sql = "INSERT INTO users ('uid', 'password', 'passphrase', 'cluster') VALUES (?, ?, ?, ?)";

	if (sqlite3_prepare_v2(dataBase, sql, -1, &stmnt, NULL) != SQLITE_OK) {
		NSLog(@"Could not prepare statement!");
		return NO;
	} else {
		sqlite3_bind_text(stmnt, 1, [[svc username] UTF8String], -1, SQLITE_TRANSIENT);
		sqlite3_bind_text(stmnt, 2, [[svc password] UTF8String], -1, SQLITE_TRANSIENT);
		sqlite3_bind_text(stmnt, 3, [[svc passphrase] UTF8String], -1, SQLITE_TRANSIENT);
		sqlite3_bind_text(stmnt, 4, [[svc baseURI] UTF8String], -1, SQLITE_TRANSIENT);
		
		if (sqlite3_step(stmnt) != SQLITE_DONE) {
			NSLog(@"Could not save user to DB!");
			sqlite3_finalize(stmnt);
			return NO;
		} else {
			NSLog([NSString stringWithFormat:@"%@ %d", @"Number of users now: ", [self getUsers]]);
			sqlite3_finalize(stmnt);
		}
	}
	
	return YES;
}

-(BOOL) loadUserToService:(Service *)svc {
	NSString *usr;
	NSString *pwd;
	NSString *pph;
	NSString *base;
	
	sqlite3_stmt *stmnt;
	const char *sql = "SELECT * FROM users LIMIT 1";
	
	if (sqlite3_prepare_v2(dataBase, sql, -1, &stmnt, NULL) == SQLITE_OK) {
		if (sqlite3_step(stmnt) == SQLITE_ROW) {
			usr = [NSString stringWithUTF8String:(char *)sqlite3_column_text(stmnt, 1)];
			pwd = [NSString stringWithUTF8String:(char *)sqlite3_column_text(stmnt, 2)];
			pph = [NSString stringWithUTF8String:(char *)sqlite3_column_text(stmnt, 3)];
			base = [NSString stringWithUTF8String:(char *)sqlite3_column_text(stmnt, 4)];
			
			[svc setUsername:usr];
			[svc setPassword:pwd];
			[svc setPassphrase:pph];
			[svc setBaseURI:base];
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

-(BOOL) addBookmarks:(NSString *)json {
	bmkUris = [[NSMutableArray alloc] init];
	bmkTitles = [[NSMutableArray alloc] init];
	
	NSArray *items = [json JSONValue];
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
				}
			}
		} @catch (id theException) {
			//NSLog(@"%@ threw %@", payload, theException);
		}
	}

	return YES;
}

-(BOOL) addHistory:(NSString *)json {
	histUris = [[NSMutableArray alloc] init];
	histTitles = [[NSMutableArray alloc] init];
	
	NSArray *items = [json JSONValue];
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
			}
		} @catch (id theException) {
			//NSLog(@"%@ threw %@", payload, theException);
		}
	}
	
	return YES;
}

-(void) dealloc {
	sqlite3_close(dataBase);
	[super dealloc];
}

@end
