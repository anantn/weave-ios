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
#import "Reachability.h"

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
	
	[[cb getStatusLabel] setAlpha:1.0];
	[[cb getStatusLabel] setText:@"Please wait while we log you in"];
	[[cb spinner] setAlpha:1.0];
	[[cb spinner] startAnimating];
	
	/* Get cluster */
	NSString *cl = [NSString
					stringWithFormat:@"https://auth.services.mozilla.com/user/1/%@/node/weave",
					username];
	[conn getResource:[NSURL URLWithString:cl] withCallback:self andIndex:8];
}

/* For non-first time users, just check for updates */
-(void) updateDataWithCallback:(TabViewController *)callback {
	Reachability* rc = [Reachability sharedReachability];
	[rc setHostName:@"services.mozilla.com"];
	NetworkStatus st = [rc remoteHostStatus];
	
	if (st != NotReachable) {
		cb = callback;
		
		NSString *cl = [NSString
						stringWithFormat:@"https://auth.services.mozilla.com/user/1/%@/node/weave",
						username];
		[conn getResource:[NSURL URLWithString:cl] withCallback:self andIndex:9];
	} else {
		UIAlertView *alert = [[UIAlertView alloc]
							  initWithTitle:@"Connection Unavailable"
							  message:@"An internet connection is not available, thus no updates will be performed"
							  delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
		[alert show];
		[alert release];
	}
}

/* Background loading of bookmarks + history for first time users */
-(void) loadDataWithCallback:(TabViewController *)callback {
	cb = callback;
	
	currentRecord = 0;
	[cb pgBar].hidden = NO;
	[cb pgText].hidden = NO;
	[cb overlay].hidden = NO;
	[[cb pgText] setText:@""];
	[[cb pgBar] setProgress:0.0];
	[[cb pgStatus] setText:@"Downloading Bookmarks"];
	
	NSString *cl = [NSString stringWithFormat:@"%@storage/bookmarks/?full=1", server];
	[conn getResource:[NSURL URLWithString:cl] withCallback:self pgIndex:3 andIndex:1];
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

-(NSMutableDictionary *) getTabs {
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

-(void) setTotal:(NSString *) stot {
	/* Hmm, Total records are always less than
	   actual total thanks to empty records */
	totalRecords = [stot intValue];
}

-(void) successWithString:(NSString *)response andIndex:(int)i{
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
			/* Got bookmarks, Now get history */
			currentRecord = 0;
			[[cb pgText] setText:@""];
			[[cb pgBar] setProgress:0.0];
			[conn getResource:[NSURL URLWithString:
				[NSString stringWithFormat:@"%@storage/history/?full=1&sort=newest", server]]
					withCallback:self pgIndex:4 andIndex:2];
			[[cb pgStatus] setText:@"Downloading History"];
			break;
		case 2:
			/* Got history, Now get favicons */
			[store setSyncTimeForUser:username];
			[self getFavicons];
			break;
		case 3:
			/* Progress for bookmarks */
			[store addBookmarkRecord:response];
			currentRecord++;
			[[cb pgText] setText:[NSString stringWithFormat:@"%d / %d",
								  currentRecord, totalRecords]];
			[[cb pgBar] setProgress:(float)currentRecord/(float)totalRecords];
			break;
		case 4:
			/* Progress for history */
			[store addHistoryRecord:response];
			currentRecord++;
			[[cb pgText] setText:[NSString stringWithFormat:@"%d / %d",
								  currentRecord, totalRecords]];
			[[cb pgBar] setProgress:(float)currentRecord/(float)totalRecords];
			break;
		case 5:
			/* Got bookmarks update, Now get history update  */
			currentRecord = 0;
			[[cb pgText] setText:@""];
			[[cb pgBar] setProgress:0.0];
			[conn getResource:[NSURL URLWithString:
							   [NSString stringWithFormat:@"%@storage/history/?full=1&sort=newest&newer=%f",
								server, [store getSyncTimeForUser:username]]] withCallback:self pgIndex:4 andIndex:6];
			[[cb pgStatus] setText:@"Updating History"];
			break;
		case 6:
			/* Got history update, set sync time and get favicons */
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
		case 8:
			/* Got cluster for a first time user, now get tabs */
			[conn setUser:username password:password passphrase:passphrase andCluster:response];
			[conn getResource:[NSURL URLWithString:
							   [NSString stringWithFormat:@"%@storage/tabs/?full=1", server]]
				 withCallback:self andIndex:0];
			break;
		case 9:
			/* Got cluster for a returning user */
			[conn setUser:username password:password passphrase:passphrase andCluster:response];
			[conn getResource:[NSURL URLWithString:
							   [NSString stringWithFormat:@"%@storage/bookmarks/?newer=%f", server, [store getSyncTimeForUser:username]]]
				withCallback:self pgIndex:3 andIndex:5];
			
			currentRecord = 0;
			[cb pgBar].hidden = NO;
			[cb pgText].hidden = NO;
			[[cb pgStatus] setText:@"Updating Bookmarks"];
			[cb overlay].hidden = NO;
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
