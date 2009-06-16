//
//  Service.m
//  Weave
//
//  Created by Anant Narayanan on 31/03/09.
//  Copyright 2009 Anant Narayanan. All rights reserved.
//

#import "Service.h"
#import "Utility.h"
#import "Store.h"
#import "Connection.h"
#import "LoginViewController.h"

@implementation Service

@synthesize username, password, passphrase;
@synthesize cb, store, conn, protocol, server, baseURI;

-(Service *) initWithServer:(NSString *)address {
	self = [super init];
	
	if (self) {
		self.server = address;
		self.protocol = @"https://";
		self.store = [[Store alloc] initWithDB:@"/store.sq3"];
		self.conn = [Connection alloc];
	}
	
	return self;
}

-(BOOL) loadFromStore {
	NSLog(@"Loading service from store...");
	return [store loadUserToService:self];
}

-(void) loadFromUser:(NSString *)user password:(NSString *)pwd passphrase:(NSString *)ph andCallback:(LoginViewController *)callback {
	cb = callback;
	password = pwd;
	username = user;
	passphrase = ph;
	
	/* We're using the crypto proxy */
	baseURI = [[NSString alloc] initWithString:[NSString stringWithFormat:@"%@%@:%@@%@/proxy/?path=",
			   protocol, username, password, server]];
	[conn setUser:user password:pwd andPassphrase:ph];
	
	/* Check username password */
	[[cb getStatusLabel] setAlpha:1.0];
	[[cb getStatusLabel] setText:@"Please wait while we log you in"];
	[[cb spinner] setAlpha:1.0];
	[[cb spinner] startAnimating];
	
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

-(NSMutableArray *)getTabURIs {
	return [store tabUris];
}

-(NSMutableArray *)getTabTitles {
	return [store tabTitles];
}


-(void) successWithString:(NSString *)response andIndex:(int)i{
	NSArray *pg;
	int tot, sof;
	NSString *url;
	NSDictionary *rp;
	
	switch (i) {
		case 0:
			/* Verified, get Bookmarks */
			[cb verified:YES];
			/*
			[[cb getStatusLabel] setText:@"Downloading your bookmarks..."];
			url = [NSString stringWithFormat:@"%@/bookmarks/?full=1", baseURI];
			
			[conn getResource:[NSURL URLWithString:url] withCallback:self pgIndex:4 andIndex:1];
			*/
			break;
		case 1:
			/* We got bookmarks, now get History 
			[[cb getProgressView] setAlpha:0.0];
			[[cb getProgressLabel] setAlpha:0.0];
			[store addBookmarks:response];
			
			[[cb getStatusLabel] setText:@"Downloading your history..."];
			[[cb getProgressView] setAlpha:1.0];
			*/
			/*
			url = [NSString stringWithFormat:@"%@/history/?full=1", baseURI];
			 */
			url = [NSString stringWithFormat:@"%@/tabs/?full=1", baseURI];
			[conn getResource:[NSURL URLWithString:url] withCallback:self pgIndex:4 andIndex:3];
			break;
		case 2:
			/* Got history, now get Tabs 
			[[cb getProgressView] setAlpha:0.0];
			[[cb getProgressLabel] setAlpha:0.0];
			[store addHistory:response];

			[[cb getStatusLabel] setText:@"Downloading your tabs..."];
			[[cb getProgressView] setAlpha:1.0];
			url = [NSString stringWithFormat:@"%@/tabs/?full=1", baseURI];
			[conn getResource:[NSURL URLWithString:url] withCallback:self pgIndex:4 andIndex:3];
			 */
			break;
		case 3:
			/* Got tabs, now add user to Store
			[[cb getProgressView] setAlpha:0.0];
			[[cb getProgressLabel] setAlpha:0.0];
			[store addTabs:response];
			
			if ([store addUserWithService:self]) {
				[cb verified:YES];
			} else {
				[cb verified:NO];
			}
			*/
			break;
		case 4:
			/* progress 
			rp = [[NSString stringWithFormat:@"%@%@", response, @"]}"] JSONValue];
			
			if (rp) {
				pg = [rp valueForKey:@"progress"];
				tot = [[rp valueForKey:@"total"] intValue];
				sof = [[pg lastObject] intValue];
				[[cb getProgressView] setProgress:(float)sof/(float)tot];
				[[cb getProgressLabel] setText:[NSString stringWithFormat:@"%d / %d", sof, tot]];
				[[cb getProgressLabel] setAlpha:1.0];
				
				if (tot - sof < 4)
					[[cb getStatusLabel] setText:@"Processing data..."];
			}
			 */
			break;
		default:
			NSLog(@"This should never happen!");
			break;
	}
}

-(void) failureWithError:(NSError *)error andIndex:(int)i{
	[[cb getStatusLabel] setText:@""];
	[cb verified:NO];
}

-(void) dealloc {
	[conn release];
	[store release];
    [super dealloc];
}

@end
