//
//  Store.h
//  Weave
//
//  Created by Anant Narayanan on 6/4/09.
//  Copyright 2009 Mozilla Corporation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

@class Service;

@interface Store : NSObject {
	sqlite3 *dataBase;
	NSMutableArray *bmkUris;
	NSMutableArray *bmkTitles;
	NSMutableArray *histUris;
	NSMutableArray *histTitles;
	NSMutableArray *tabUris;
	NSMutableArray *tabTitles;
}

@property (nonatomic) sqlite3 *dataBase;
@property (nonatomic, retain) NSMutableArray *bmkUris;
@property (nonatomic, retain) NSMutableArray *bmkTitles;
@property (nonatomic, retain) NSMutableArray *histUris;
@property (nonatomic, retain) NSMutableArray *histTitles;
@property (nonatomic, retain) NSMutableArray *tabUris;
@property (nonatomic, retain) NSMutableArray *tabTitles;

-(Store *) initWithDB:(NSString *)db;

-(BOOL) addTabs:(NSString *)json;
-(BOOL) addHistory:(NSString *)json;
-(BOOL) addBookmarks:(NSString *)json;

-(BOOL) loadUserToService:(Service *)svc;
-(BOOL) addUserWithService:(Service *)svc;
-(BOOL) setSyncTimeForUser:(NSString *)user;
-(double) getSyncTimeForUser:(NSString *)user;

-(int) getUsers;

@end
