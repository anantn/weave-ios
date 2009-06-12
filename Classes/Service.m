//
//  Service.m
//  Weave
//
//  Created by Anant Narayanan on 31/03/09.
//  Copyright 2009 Anant Narayanan. All rights reserved.
//

#import "Service.h"
#import "Utility.h"
#import "Crypto.h"
#import "Store.h"
#import "Connection.h"
#import "Verifier.h"

@implementation Service

@synthesize username, password, passphrase;
@synthesize cb, iv, salt, public_key, private_key;
@synthesize store, conn, crypto, protocol, server, baseURI;

-(Service *) initWithServer:(NSString *)address {
	self = [super init];
	
	if (self) {
		self.server = address;
		self.protocol = @"https://";
		self.store = [[Store alloc] initWithDB:@"/store.sq3"];
		self.crypto = [Crypto alloc];
		self.conn = [Connection alloc];
	}
	
	return self;
}

-(BOOL) loadFromStore {
	return [store loadUserToService:self];
}

-(void) loadFromUser:(NSString *)user password:(NSString *)pwd passphrase:(NSString *)ph andCallback:(id)callback {
	cb = callback;
	password = pwd;
	username = user;
	passphrase = ph;
	
	/* We're using the crypto proxy */
	baseURI = [NSString stringWithFormat:@"%@%@:%@@%@/proxy/?path=",
			   protocol, username, password, server];
	[conn setUser:user password:pwd andPassphrase:ph];
	
	/* Get bookmarks */
	NSString *cl = [NSString stringWithFormat:@"%@/bookmarks/?full=1", baseURI];
	[conn getResource:[NSURL URLWithString:cl] withCallback:self andIndex:0];
}

-(NSMutableArray *) getBookmarkURIs {
	return [store bmkUris];
}

-(NSMutableArray *)getBookmarkTitles {
	NSLog(@"%@", [store bmkTitles]);
	return [store bmkTitles];
}

-(void) successWithString:(NSString *)response andIndex:(int)i{
	switch (i) {
		case 0:
			/* We got bookmarks */
			[store addBookmarks:response];
			[cb verified:YES];
			break;
		default:
			NSLog(@"This should never happen!");
			break;
	}
}

-(void) failureWithError:(NSError *)error andIndex:(int)i{
	[cb verified:NO];
}

-(void) dealloc {
	[conn release];
	[store release];
    [super dealloc];
}

@end
