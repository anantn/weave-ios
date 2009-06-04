//
//  Store.m
//  Weave
//
//  Created by Anant Narayanan on 6/4/09.
//  Copyright 2009 Mozilla Corporation. All rights reserved.
//

#import "Store.h"

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
