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
#import "Crypto.h"
#import "Service.h"
#import "Utility.h"
#import "Connection.h"
#import "TabViewController.h"
#import "LoginViewController.h"
#import "Reachability.h"

@implementation Service

@synthesize cb, store, conn, favs;
@synthesize crypto, username, password, passphrase;

-(Service *) init {
	self = [super init];
	
	if (self) {
		self.store = [[Store alloc] initWithDB:@"/store.sq3"];
		self.conn = [Connection alloc];
		self.crypto = [[Crypto alloc] initWithService:self];
	}
	
	return self;
}

-(BOOL) loadFromStore {
	NSLog(@"Loading service from store...");
	return [store loadUserToService:self];
}

/* For first time users. First order of business: get cluster */
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
	isFirst = YES;
	NSString *cl = [NSString stringWithFormat:NODE_CHECK, username];
	[conn getResource:[NSURL URLWithString:cl] withCallback:self andIndex:GOT_CLUSTER];
}

/* For non-first time users, first check connectivity because LoginController didn't appear
   Then, update the user's cluster */
-(void) updateDataWithCallback:(TabViewController *)callback {
	Reachability* rc = [Reachability sharedReachability];
	[rc setHostName:SERV_BASE];
	NetworkStatus st = [rc remoteHostStatus];
	
	if (st != NotReachable) {
		cb = callback;
		isFirst = NO;
		NSString *cl = [NSString stringWithFormat:NODE_CHECK, username];
		[conn getResource:[NSURL URLWithString:cl] withCallback:self andIndex:GOT_CLUSTER];
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
	
	[conn getRelativeResource:BMARKS_U withCallback:self pgIndex:BMARKS_PROGRESS andIndex:GOT_BMARKS];
}

/* Callback from Crypto setup */
-(void) cryptoDone:(BOOL)res
{
	NSLog(@"Crypto done called with %d", res);
	if (res) {
		if (isFirst) {
			[conn getRelativeResource:TABS_U withCallback:self andIndex:GOT_TABS];
		} else {
			[conn getRelativeResource:TABS_U withCallback:self andIndex:GOT_TABS_UP];
		}
	} else {
		if (isFirst)
			[self failureWithError:nil andIndex:0];
		else
			[self failureWithError:nil andIndex:1];
	}
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
	
	[conn postTo:[NSURL URLWithString:FAVICONS_U] withData:postParams callback:self andIndex:GOT_FAVICONS];
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
	NSArray *records;
	
	switch (i) {
		case GOT_TABS:
			/* Got tabs, now add user to Store
			[store addTabs:response];
			if ([store addUserWithService:self]) {
				[cb verified:YES];
			} else {
				[cb verified:NO];
			}
			 */
			records = [response JSONValue];
			[crypto decryptWBO:[records objectAtIndex:[records count] - 1]];
			/*
			for (NSDictionary *rec in records) {
				[crypto decryptWBO:rec];
			}
			*/
			break;
		case GOT_TABS_UP:
			/* Got tabs for returning user, get bookmarks update 
			[store addTabs:response];
			[conn getRelativeResource:[NSString stringWithFormat:BMARKS_UP,
									   [store getSyncTimeForUser:username]]
						 withCallback:self pgIndex:BMARKS_PROGRESS andIndex:GOT_BMARKS];
			
			currentRecord = 0;
			[cb pgBar].hidden = NO;
			[cb pgText].hidden = NO;
			[[cb pgStatus] setText:@"Updating Bookmarks"];
			[cb overlay].hidden = NO;
			 */
			NSLog(@"%@", response);
			break;
		case GOT_BMARKS:
			/* Got bookmarks, Now get history */
			currentRecord = 0;
			[[cb pgText] setText:@""];
			[[cb pgBar] setProgress:0.0];
			[conn getRelativeResource:HISTORY_U withCallback:self pgIndex:HISTORY_PROGRESS andIndex:GOT_HISTORY];
			[[cb pgStatus] setText:@"Downloading History"];
			break;
		case GOT_HISTORY:
			/* Got history, Now get favicons */
			[store setSyncTimeForUser:username];
			[self getFavicons];
			break;
		case BMARKS_PROGRESS:
			/* Progress for bookmarks */
			[store addBookmarkRecord:response];
			currentRecord++;
			[[cb pgText] setText:[NSString stringWithFormat:@"%d / %d",
								  currentRecord, totalRecords]];
			[[cb pgBar] setProgress:(float)currentRecord/(float)totalRecords];
			break;
		case HISTORY_PROGRESS:
			/* Progress for history */
			[store addHistoryRecord:response];
			currentRecord++;
			[[cb pgText] setText:[NSString stringWithFormat:@"%d / %d",
								  currentRecord, totalRecords]];
			[[cb pgBar] setProgress:(float)currentRecord/(float)totalRecords];
			break;
		case GOT_BMARKS_UP:
			/* Got bookmarks update, Now get history update  */
			currentRecord = 0;
			[[cb pgText] setText:@""];
			[[cb pgBar] setProgress:0.0];
			[conn getRelativeResource:[NSString stringWithFormat:HISTORY_UP, 
							   [store getSyncTimeForUser:username]] withCallback:self pgIndex:HISTORY_PROGRESS andIndex:GOT_HISTORY_UP];
			[[cb pgStatus] setText:@"Updating History"];
			break;
		case GOT_HISTORY_UP:
			/* Got history update, set sync time and get favicons */
			[store setSyncTimeForUser:username];
			[self getFavicons];
			break;
		case GOT_FAVICONS:
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
				[conn postTo:[NSURL URLWithString:FAVICONS_U] withData:postParams callback:self andIndex:GOT_FAVICONS];
			}
			break;
		case GOT_CLUSTER:
			/* Got cluster */
			[conn setUser:username password:password passphrase:passphrase andCluster:response];
			/* Fetch user's public key */
			[conn getRelativeResource:PUBKEY_U withCallback:crypto andIndex:GOT_PUB_KEY];
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
