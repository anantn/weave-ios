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
#import "LoginViewController.h"

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
	baseURI = [[NSString alloc] initWithString:[NSString stringWithFormat:@"%@%@:%@@%@/proxy/?path=",
			   protocol, username, password, server]];
	[conn setUser:user password:pwd andPassphrase:ph];
	
	/* Check username password */
	[[cb status] setText:@"Checking your credentials..."];
	[[cb status] setAlpha:1.0];
	 
	NSString *cl = [NSString stringWithFormat:@"%@/clients", baseURI];
	[conn getResource:[NSURL URLWithString:cl] withCallback:self andIndex:0];
}

-(NSMutableArray *) getBookmarkURIs {
	return [store bmkUris];
}

-(NSMutableArray *)getBookmarkTitles {
	return [store bmkTitles];
}

-(NSMutableArray *)getHistoryURIs {
	return [store histUris];
}

-(NSMutableArray *)getHistoryTitles {
	return [store histTitles];
}

-(void) successWithString:(NSString *)response andIndex:(int)i{
	NSString *url;
	
	switch (i) {
		case 0:
			/* Verified, get history */
			[[cb status] setText:@"Downloading your bookmarks..."];
			url = [NSString stringWithFormat:@"%@/bookmarks/?full=1", baseURI];
			
			[conn getResource:[NSURL URLWithString:url] withCallback:self andIndex:1];
			break;
		case 1:
			/* We got bookmarks, now get History */
			[store addBookmarks:response];
			[[cb status] setText:@"Downloading your history..."];
			url = [NSString stringWithFormat:@"%@/history/?full=1", baseURI];
			[conn getResource:[NSURL URLWithString:url] withCallback:self andIndex:2];
			break;
		case 2:
			/* Got history, done! 
			[store addHistory:response];
			*/
			[cb verified:YES];
		default:
			NSLog(@"This should never happen!");
			break;
	}
}

-(void) failureWithError:(NSError *)error andIndex:(int)i{
	[[cb status] setText:@""];
	[[cb status] setAlpha:0.0];
	[cb verified:NO];
}

-(void) dealloc {
	[conn release];
	[store release];
    [super dealloc];
}

@end
