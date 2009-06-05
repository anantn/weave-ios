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
}

@property (nonatomic) sqlite3 *dataBase;

-(Store *) initWithDB:(NSString *)db;

-(BOOL) loadUserToService:(Service *)svc;
-(BOOL) addUserWithService:(Service *)svc;

-(int) getUsers;

@end
