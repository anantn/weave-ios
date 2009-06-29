//
//  Service.m
//  Weave
//
//  Created by Anant Narayanan on 31/03/09.
//  Copyright 2009 Anant Narayanan. All rights reserved.
//

#import "Store.h"
#import "Service.h"
#import "Utility.h"
#import "Connection.h"
#import "TabViewController.h"
#import "LoginViewController.h"

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
-(void) loadDataWithCallback:(TabViewController *)callback {
	cb = callback;
	NSString *cl = [NSString stringWithFormat:@"%@bookmarks/?full=1", server];
	[conn getResource:[NSURL URLWithString:cl] withCallback:self pgIndex:3 andIndex:1];
	
	[[cb pgStatus] setText:@"Downloading Bookmarks"];
	[cb overlay].hidden = NO;
}

/* For non-first time users,just check for updates */
-(void) updateDataWithCallback:(TabViewController *)callback {
	cb = callback;
	[conn setUser:username password:password andPassphrase:passphrase];
	NSString *cl = [NSString stringWithFormat:@"%@bookmarks/?newer=%f", server, [store getSyncTimeForUser:username]];
	[conn getResource:[NSURL URLWithString:cl] withCallback:self pgIndex:3 andIndex:5];
	
	[[cb pgStatus] setText:@"Updating Bookmarks"];
	[cb overlay].hidden = NO;
}

-(NSDate *)getSyncTime {
	return [NSDate dateWithTimeIntervalSince1970:[store getSyncTimeForUser:username]];
}

-(NSMutableArray *) getBookmarkURIs {
	return [store bmkUris];
}

-(NSMutableArray *) getBookmarkTitles {
	return [store bmkTitles];
}

-(NSMutableArray *) getHistoryURIs {
	return [store histUris];
}

-(NSMutableArray *) getHistoryTitles {
	return [store histTitles];
}

-(NSMutableArray *) getTabURIs {
	return [store tabUris];
}

-(NSMutableArray *) getTabTitles {
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
			[store addBookmarks:response];
			
			/* Now get history */
			[conn getResource:[NSURL URLWithString:
				[NSString stringWithFormat:@"%@history/?full=1&sort=oldest", server]]
					withCallback:self pgIndex:4 andIndex:2];
			[[cb pgStatus] setText:@"Downloading History"];
			break;
		case 2:
			/* Got history */
			[store addHistory:response];
			
			/* Done! */
			[store setSyncTimeForUser:username];
			[cb downloadComplete:YES];
			break;
		case 3:
			/* Progress for bookmarks download */
			rp = [[NSString stringWithFormat:@"%@%@", response, @"]}"] JSONValue];
			
			if (rp) {
				pg = [rp valueForKey:@"progress"];
				
				c = [[pg lastObject] intValue];
				tot = [[rp valueForKey:@"total"] intValue];
				
				if (tot - c < 4) {
					[[cb pgStatus] setText:@"Processing Bookmarks"];
					[cb pgBar].hidden = YES;
					[cb pgText].hidden = YES;
				} else {
					[[cb pgText] setText:[NSString stringWithFormat:@"%d / %d", c, tot]];
					[[cb pgBar] setProgress:(float)c/(float)tot];
					[cb pgBar].hidden = NO;
					[cb pgText].hidden = NO;
				}
			}
			break;
		case 4:
			/* Progress for history download */
			rp = [[NSString stringWithFormat:@"%@%@", response, @"]}"] JSONValue];
			
			if (rp) {
				pg = [rp valueForKey:@"progress"];
				c = [[pg lastObject] intValue];
				tot = [[rp valueForKey:@"total"] intValue];
				
				if (tot - c < 4) {
					[[cb pgStatus] setText:@"Processing History"];
					[cb pgBar].hidden = YES;
					[cb pgText].hidden = YES;
				} else {
					[[cb pgText] setText:[NSString stringWithFormat:@"%d / %d", c, tot]];
					[[cb pgBar] setProgress:(float)c/(float)tot];
					[cb pgBar].hidden = NO;
					[cb pgText].hidden = NO;
				}
			}
			break;
		case 5:
			/* Got bookmarks update */
			if (tot != 0) {
				[store addBookmarks:response];
			}
			
			/* Now get history update*/
			[conn getResource:[NSURL URLWithString:
							   [NSString stringWithFormat:@"%@history/?full=1&sort=oldest&newer=%f",
								server, [store getSyncTimeForUser:username]]] withCallback:self pgIndex:4 andIndex:6];
			[[cb pgStatus] setText:@"Updating History"];
			break;
		case 6:
			/* Got history update */
			if (tot != 0) {
				[store addHistory:response];
			}
			[store setSyncTimeForUser:username];
			[cb downloadComplete:YES];
			break;
		default:
			NSLog(@"This should never happen!");
			break;
	}
}

-(void) failureWithError:(NSError *)error andIndex:(int)i{
	if (i == 0)
		[cb verified:NO];
	else
		[cb downloadComplete:NO];
}

-(void) dealloc {
	[conn release];
	[store release];
    [super dealloc];
}

@end
