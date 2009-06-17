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
#import "MainViewController.h"

@implementation Service

@synthesize cb, store, conn, server;
@synthesize username, password, passphrase;

-(Service *) initWithServer:(NSString *)address {
	self = [super init];
	
	if (self) {
		self.server = address;
		self.store = [[Store alloc] initWithDB:@"/store.sq3"];
		self.conn = [Connection alloc];
	}
	
	return self;
}

-(BOOL) loadFromStore {
	NSLog(@"Loading service from store...");
	return [store loadUserToService:self];
}

/* For first time users. We verify username/passwords and check passphrase by storing open tabs */
-(void) loadFromUser:(NSString *)user password:(NSString *)pwd passphrase:(NSString *)ph andCallback:(LoginViewController *)callback {
	cb = callback;
	password = pwd;
	username = user;
	passphrase = ph;
	
	/* We're using the crypto proxy */
	[conn setUser:user password:pwd andPassphrase:ph];
	
	[[cb getStatusLabel] setAlpha:1.0];
	[[cb getStatusLabel] setText:@"Please wait while we log you in"];
	[[cb spinner] setAlpha:1.0];
	[[cb spinner] startAnimating];
	
	NSString *cl = [NSString stringWithFormat:@"%@tabs/?full=1", server];
	[conn getResource:[NSURL URLWithString:cl] withCallback:self andIndex:0];
}

/* Background loading of bookmarks + history */
-(void) loadDataWithCallback:(MainViewController *)callback {
	cb = callback;
	NSString *cl = [NSString stringWithFormat:@"%@bookmarks/?full=1", server];
	
	[[cb pgTitle] setText:@"Downloading Bookmarks"];
	[cb pgTitle].hidden = NO;
	
	[conn getResource:[NSURL URLWithString:cl] withCallback:self pgIndex:3 andIndex:1];
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
	int tot, c;
	NSArray *pg;
	NSDictionary *rp;

	switch (i) {
		case 0:
			/* Got tabs, now add user to Store */
			[store addTabs:response];
			
			if ([store addUserWithService:self]) {
				[cb verified:YES];
			} else {
				[cb verified:NO];
			}
			break;
		case 1:
			/* Got bookmarks */
			[cb pgBar].hidden = YES;
			[[cb pgTitle] setText:@"Storing Bookmarks"];
			[store addBookmarks:response];
			
			/* Now get history */
			[[cb pgTitle] setText:@"Downloading History"];
			[conn getResource:[NSURL URLWithString:
				[NSString stringWithFormat:@"%@history/?full=1", server]]
					withCallback:self pgIndex:4 andIndex:2];
			break;
		case 2:
			/* Got history */
			[cb pgBar].hidden = YES;
			[[cb pgTitle] setText:@"Storing History"];
			[store addHistory:response];
			
			/* Success */
			[cb downloadComplete:YES];
			break;
		case 3:
			rp = [[NSString stringWithFormat:@"%@%@", response, @"]}"] JSONValue];
			
			if (rp) {
				pg = [rp valueForKey:@"progress"];
				
				c = [[pg lastObject] intValue];
				tot = [[rp valueForKey:@"total"] intValue];
				
				[[cb pgBar] setProgress:(float)c/(float)tot];
				[[cb pgTitle] setText:[NSString stringWithFormat:@"Downloading Bookmarks: %d/%d", c, tot]];
				
				if (tot - c < 4) {
					[cb pgBar].hidden = YES;
					[[cb pgTitle] setText:@"Processing Bookmarks"];
				} else {
					if ([cb pgBar].hidden)
						[cb pgBar].hidden = NO;
				}
			}
			break;
		case 4:
			rp = [[NSString stringWithFormat:@"%@%@", response, @"]}"] JSONValue];
			
			if (rp) {
				pg = [rp valueForKey:@"progress"];
				
				c = [[pg lastObject] intValue];
				tot = [[rp valueForKey:@"total"] intValue];
				
				[[cb pgBar] setProgress:(float)c/(float)tot];
				[[cb pgTitle] setText:[NSString stringWithFormat:@"Downloading History: %d/%d", c, tot]];
				
				if (tot - c < 4) {
					[cb pgBar].hidden = YES;
					[[cb pgTitle] setText:@"Processing History"];
				} else {
					if ([cb pgBar].hidden)
						[cb pgBar].hidden = NO;
				}
			}
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
