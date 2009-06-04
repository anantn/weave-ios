//
//  Store.h
//  Weave
//
//  Created by Anant Narayanan on 6/4/09.
//  Copyright 2009 Mozilla Corporation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

@interface Store : NSObject {
	sqlite3 *dataBase;
}

@property (nonatomic) sqlite3 *dataBase;

-(Store *) initWithDB:(NSString *)db;
-(int) getUsers;

@end
