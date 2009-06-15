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
}

@property (nonatomic) sqlite3 *dataBase;
@property (nonatomic, retain) NSMutableArray *bmkUris;
@property (nonatomic, retain) NSMutableArray *bmkTitles;
@property (nonatomic, retain) NSMutableArray *histUris;
@property (nonatomic, retain) NSMutableArray *histTitles;

-(Store *) initWithDB:(NSString *)db;

-(BOOL) loadUserToService:(Service *)svc;
-(BOOL) addUserWithService:(Service *)svc;
-(BOOL) addBookmarks:(NSString *)json;
-(BOOL) addHistory:(NSString *)json;

-(int) getUsers;

@end
