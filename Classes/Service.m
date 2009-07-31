/***** BEGIN LICENSE BLOCK *****
 Version: MPL 1.1
 
 The contents of this file are subject to the Mozilla Public License Version 
 1.1 (the "License"); you may not use this file except in compliance with 
 the License. You may obtain a copy of the License at 
 http://www.mozilla.org/MPL/
 
 Software distributed under the License is distributed on an "AS IS" basis,
 WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 for the specific language governing rights and limitations under the
 License.
 
 The Original Code is weave-iphone.
 
 The Initial Developer of the Original Code is Mozilla Labs.
 Portions created by the Initial Developer are Copyright (C) 2009
 the Initial Developer. All Rights Reserved.
 
 Contributor(s):
	Anant Narayanan <anant@kix.in>
 
 ***** END LICENSE BLOCK *****/

#import "Store.h"
#import "Service.h"
#import "Utility.h"
#import "Connection.h"
#import "TabViewController.h"
#import "LoginViewController.h"

@implementation Service

@synthesize cb, store, conn, server, favs;
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

/* For non-first time users, just check for updates */
-(void) updateDataWithCallback:(TabViewController *)callback {
	cb = callback;
	[conn setUser:username password:password andPassphrase:passphrase];
	NSString *cl = [NSString stringWithFormat:@"%@bookmarks/?newer=%f", server, [store getSyncTimeForUser:username]];
	[conn getResource:[NSURL URLWithString:cl] withCallback:self pgIndex:3 andIndex:5];
	
	[[cb pgStatus] setText:@"Updating Bookmarks"];
	[cb overlay].hidden = NO;
}

-(void) getFavicons {
	NSMutableDictionary *uris = [[NSMutableDictionary alloc] init];

	NSArray *obj;
	NSEnumerator *iter = [[store bookmarks] objectEnumerator];
	while (obj = [iter nextObject]) {
		if ([obj count] > 2)
			[uris setObject:[obj objectAtIndex:1] forKey:[obj objectAtIndex:2]];
	}
	iter = [[store history] objectEnumerator];
	while (obj = [iter nextObject]) {
		if ([obj count] > 2)
			[uris setObject:[obj objectAtIndex:1] forKey:[obj objectAtIndex:2]];
	}
	iter = [[store tabs] objectEnumerator];
	while (obj = [iter nextObject]) {
		if ([obj count] > 2)
			[uris setObject:[obj objectAtIndex:1] forKey:[obj objectAtIndex:2]];
	}
	
	/* We must fetch favicons in batches of 20 */
	NSString *postParams;
	[[cb pgStatus] setText:@"Dowloading Favicons"];	
	favs = [[NSArray alloc] initWithArray:[uris allKeys]];
	[uris release];
	
	if ([favs count] <= 20) {
		postParams = [NSString stringWithFormat:@"urls=%@", [favs JSONRepresentation]];
		favsIndex = -1;
	} else {
		NSRange range;
		range.location = 0;
		range.length = 20;
		favsIndex = range.length;
		postParams = [NSString stringWithFormat:@"urls=%@", [[favs subarrayWithRange:range] JSONRepresentation]];
	}
	
	[conn postTo:[NSURL URLWithString:@"https://services.mozilla.com/favicons/"] withData:postParams callback:self andIndex:7];
}

-(NSDate *) getSyncTime {
	return [NSDate dateWithTimeIntervalSince1970:[store getSyncTimeForUser:username]];
}

-(NSMutableArray *) getTabs {
	return [store tabs];
}

-(NSMutableArray *) getHistory {
	return [store history];
}

-(NSMutableArray *) getBookmarks {
	return [store bookmarks];
}

-(NSMutableDictionary *) getIcons {
	return [store favicons];
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
			
			/* Now get favicons */
			[store setSyncTimeForUser:username];
			[self getFavicons];
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
			[self getFavicons];
			break;
		case 7:
			/* Got 20 favicons, check if there's more or done */
			[store addFavicons:response];
			
			if (favsIndex == -1) {
				[cb downloadComplete:YES];
			} else {
				NSRange range;
				if ([favs count] <= favsIndex + 20) {
					range.location = favsIndex;
					range.length = [favs count] - favsIndex;
					favsIndex = -1;
				} else {
					range.location = favsIndex;
					range.length = 20;
					favsIndex += range.length;
				}
				NSString *postParams = [NSString stringWithFormat:@"urls=%@", [[favs subarrayWithRange:range] JSONRepresentation]];
				[conn postTo:[NSURL URLWithString:@"https://services.mozilla.com/favicons/"] withData:postParams callback:self andIndex:7];
			}
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
