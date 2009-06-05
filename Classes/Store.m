//
//  Store.m
//  Weave
//
//  Created by Anant Narayanan on 6/4/09.
//  Copyright 2009 Mozilla Corporation. All rights reserved.
//

#import "Service.h"

@implementation Store

@synthesize dataBase;

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
			if (sqlite3_open([writablePath UTF8String], &dataBase) == SQLITE_OK)
				return self;
			else
				NSLog(@"Could not open database!");
		}
		
		/* DB doesn't exist, copy from resource bundle */
		NSString *defaultDB = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:db];
		success = [fm copyItemAtPath:defaultDB toPath:writablePath error:&error];
		if (success) {
			if (sqlite3_open([writablePath UTF8String], &dataBase) == SQLITE_OK)
				return self;
			else
				NSLog(@"Could not open database!");
		} else {
			NSLog(@"Could not create database!");
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
			return NO;
		}
		sqlite3_reset(stmnt);
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
			return NO;
		}
	} else {
		NSLog(@"Could not prepare SQL to LOAD!");
		return NO;
	}
	
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
	
	return cnt;
}

@end
