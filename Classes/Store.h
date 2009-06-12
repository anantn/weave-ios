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
	NSMutableArray *listOfBmks;
}

@property (nonatomic) sqlite3 *dataBase;
@property (nonatomic, retain) NSMutableArray *listOfBmks;

-(Store *) initWithDB:(NSString *)db;

-(BOOL) loadUserToService:(Service *)svc;
-(BOOL) addUserWithService:(Service *)svc;
-(BOOL) addBookmarks:(NSString *)json;

-(int) getUsers;

@end
