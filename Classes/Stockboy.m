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
	Dan Walkowski <dan.walkowski@gmail.com>
 
 ***** END LICENSE BLOCK *****/

#import "Stockboy.h"
#import "Store.h"
#import "Fetcher.h"
#import "Reachability.h"
#import "Utility.h"
#import "WeaveAppDelegate.h"
#import "CryptoUtils.h"

#import "NSString+SBJSON.h"


@interface Stockboy (PRIVATE)
- (void) getCluster;
- (NSDictionary*) extractBulkKeyFrom:(NSData*)bulkKeyData;

// these should probably return something useful
- (void) updateTabs;
- (void) updateBookmarks;
- (void) updateHistory;
@end

@implementation Stockboy

// The singleton instance
static Stockboy *_gStockboy = nil;

// public resource, needed by more than one class
static NSDictionary *_gNetworkPaths = nil;

// CLASS METHODS
+(void) restock
{
	if (_gStockboy == nil) {
		_gStockboy = (id)1; //minimize race condition
		_gStockboy = [[Stockboy alloc] init];

		NSThread* keyThread = [[NSThread alloc] initWithTarget:_gStockboy selector:@selector(restockEverything) object:nil];
		[keyThread start];
	}
}

////INSTANCE METHODS//

-(Stockboy *) init 
{
	self = [super init];
	if (self) {
		_cluster = nil;
		
		// cache a copy of this for speed.
		// we were looking it up for every decrypt
		_privateKey = [CryptoUtils _getKeyNamed:PRIV_KEY_NAME];
		_symKeys = [[NSMutableDictionary alloc] init];
	}
	
	return self;
}

+(NSString*) urlForWeaveObject:(NSString*)name
{
	if (_gNetworkPaths == nil) {
		NSString *error = nil;
		NSPropertyListFormat format;
		NSString *pathtoPaths = [[NSBundle mainBundle] pathForResource:@"NetworkPaths" ofType:@"plist"];
		NSData *pathsXML = [[NSFileManager defaultManager] contentsAtPath:pathtoPaths];
		NSDictionary *thePaths = (NSDictionary *)[NSPropertyListSerialization
												  propertyListFromData:pathsXML
												  mutabilityOption:NSPropertyListMutableContainersAndLeaves
												  format:&format errorDescription:&error];

		if (!thePaths) {
			NSLog(@"%@", error);
			[error release];
			_gNetworkPaths = nil;
			return nil;
		} else {
			_gNetworkPaths = [thePaths retain];
		}
	}
	return [_gNetworkPaths objectForKey:name];
}


-(BOOL) hasConnectivity
{
	Reachability *rc = [Reachability sharedReachability];
	[rc setHostName:[Stockboy urlForWeaveObject:@"Service Base URL"]];
	return ([rc remoteHostStatus] != NotReachable);
}

// Get the cluster
// This is synchronous, since we can't make any other requests until we have it.
-(void) getCluster
{
	NSString *cl = [NSString stringWithFormat:[Stockboy urlForWeaveObject:@"Node Query URL"], [[Store getStore] getUsername]];  
	NSData *clusterData = [Fetcher getAbsoluteURLSynchronous:cl];
	_cluster = [[NSString alloc] initWithData:clusterData encoding:NSUTF8StringEncoding];
}  


-(void) restockEverything
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	if ([self hasConnectivity] && _privateKey) {
		[self getCluster];
		[self updateTabs];
		[self updateBookmarks];
		[self updateHistory];
	}

	_gStockboy = nil;
	[pool drain];
}

-(void) updateTabs
{  
	// Don't need to check timestamp.
	// We always get all the tabs, regardless of any timestamp.  
	
	// synchronous request.  we are running in a separate thread, so it's ok to block.
	NSData *tabs = [[Fetcher getURLSynchronous:[Stockboy urlForWeaveObject:@"Tabs URL"] fromCluster:_cluster] retain];
	if (tabs == nil) return; //better error handling
  
	// this will hold all the resultant decrypted tabs
	NSMutableDictionary *userTabs = [NSMutableDictionary dictionary];
  
	// This bit of primitive parsing relies on the data coming as a dictionary of dictionaries.
	// beware of 'does not understand' exceptions
	NSString *tabsString = [[[NSString alloc] initWithData:tabs encoding:NSUTF8StringEncoding] retain];
	NSDictionary *tabsDict = [tabsString JSONValue];
	NSEnumerator *tabIterator = [tabsDict objectEnumerator];
  
	NSDictionary *tabBundle;
	while (tabBundle = [tabIterator nextObject]) {
		// get the interesting bits out of the bundle    
		NSDictionary *encryptedTab = [[[tabBundle objectForKey:@"payload"] JSONValue] retain];
		NSString *keyURL = [encryptedTab objectForKey:@"encryption"];
		NSString *tabID = [tabBundle objectForKey:@"id"];
		NSLog(@"Got Tab ID:%@", tabID);
    
		// check if we have the bulk key, if not fetch it again
		NSDictionary *theKey;
		if ((theKey = [_symKeys objectForKey:keyURL]) == nil) {
			NSData *keyBundle = [Fetcher getAbsoluteURLSynchronous:keyURL];
			theKey = [self extractBulkKeyFrom:keyBundle];
			[_symKeys setValue:theKey forKey:keyURL];
		}

		// Do the decrypt and save the result keyed by id
		[userTabs setObject:[CryptoUtils decryptObject:encryptedTab withKey:theKey] forKey:tabID];
	}
	
	// Ok, now we have all the tabs, decrypted.
	// Use a transaction to put them in the database safely
	[[Store getStore] beginTransaction];
  
	// First, delete all the existing tabs.
	[[Store getStore] clearTabs];  
  
	// Second, insert all the new tabs 
	for (NSString* anID in [userTabs allKeys]) {
		[[Store getStore] addTabSet:[userTabs objectForKey:anID] withClientID:anID];
	}
	[[Store getStore] endTransaction];
}


-(void) updateBookmarks
{
	NSString *bmarksURL = [NSString stringWithFormat:[Stockboy urlForWeaveObject:@"Bookmarks Update URL"], [[Store getStore] getBookmarksSyncTime]];
	NSData *bmarks = [[Fetcher getURLSynchronous:bmarksURL fromCluster:_cluster] retain];
	if (bmarks == nil) return; //better error handling
  
	// This will hold all the resultant decrypted bookmarks that need to be added
	NSMutableDictionary *userBmarks = [NSMutableDictionary dictionary];

	// This will hold all the resultant decrypted bookmarks that need to be deleted
	NSMutableArray *userDeadBmarks = [NSMutableArray array];

	// Unpack the bookmarks
	NSString *bmarksString = [[[NSString alloc] initWithData:bmarks encoding:NSUTF8StringEncoding] retain];
	NSDictionary *bmarksDict = [bmarksString JSONValue];
	NSEnumerator *bmarkIterator = [bmarksDict objectEnumerator];

	NSDictionary* bmarkBundle;
	while (bmarkBundle = [bmarkIterator nextObject]) {
		NSString *bmarkID = [bmarkBundle objectForKey:@"id"];
		NSString *bmarkPayload = [bmarkBundle objectForKey:@"payload"];
		NSLog(@"Got Bookmark ID:%@", bmarkID);

		if (bmarkPayload == nil || [bmarkPayload length] == 0) {
			[userDeadBmarks addObject:bmarkID];
		} else {
			NSDictionary *encryptedBmark = [[bmarkPayload JSONValue] retain];
			NSString *keyURL = [encryptedBmark objectForKey:@"encryption"];
		
			NSDictionary *theKey;
			if ((theKey = [_symKeys objectForKey:keyURL]) == nil) {
				NSData *keyBundle = [Fetcher getAbsoluteURLSynchronous: keyURL];
				theKey = [self extractBulkKeyFrom:keyBundle];
				[_symKeys setValue:theKey forKey:keyURL];
			}

			// Do the decrypt
			NSString* plaintextBmark = [CryptoUtils decryptObject:encryptedBmark withKey:theKey];
			
			// Hmm, sometimes plaintext appears to be nil. Why?
			if (plaintextBmark != nil) {
				[userBmarks setObject:plaintextBmark forKey:bmarkID];
			}
			[userBmarks setObject:plaintextBmark forKey: bmarkID];
		}
	}
  
	// We have all the bookmarks, decrypted.  use a transaction to put them in the database safely
	// This can easily all be moved into the Store, and just pass in both lists
	[[Store getStore] beginTransaction];

	// First, delete all the dead bookmarks.
	for (NSString* anID in userDeadBmarks) {
		[[Store getStore] removeRecord: anID];
	}
	
	// Second, insert all the new bookmarks 
	for (NSString* anID in [userBmarks allKeys]) {
		[[Store getStore] addBookmarkRecord:[userBmarks objectForKey:anID] withID:anID];
	}
  
	[[Store getStore] updateBookmarksSyncTime];
	[[Store getStore] endTransaction];
}

-(void) updateHistory
{
	// Synchronous request.  we are running in a separate thread, so it's ok to block.
	NSString *historyURL = [NSString stringWithFormat:[Stockboy urlForWeaveObject:@"History Update URL"], [[Store getStore] getHistorySyncTime]];
	NSData *history = [[Fetcher getURLSynchronous:historyURL fromCluster:_cluster] retain];
	if (history == nil) return; //better error handling
  
	// this will hold all the resultant decrypted history entries that need to be added
	NSMutableDictionary *userHistory = [NSMutableDictionary dictionary];
  
	// this will hold all the resultant decrypted history entries that need to be deleted
	NSMutableArray *userDeadHistory = [NSMutableArray array];
	
	// unpack the history entries
	NSString *historyString = [[[NSString alloc] initWithData:history encoding:NSUTF8StringEncoding] retain];
	NSDictionary *historyDict = [historyString JSONValue];
	NSEnumerator *historyIterator = [historyDict objectEnumerator];
	
	NSDictionary *historyBundle;
	while (historyBundle = [historyIterator nextObject]) {
		NSString *historyID = [historyBundle objectForKey:@"id"];
		NSString *historyPayload = [historyBundle objectForKey:@"payload"];
		NSLog(@"Got History ID:%@", historyID);
    
		// does the payload not exist for deleted history entries?
		if (historyPayload ==  nil || [historyPayload length] == 0) {
			[userDeadHistory addObject:historyID];
		} else {
			NSDictionary *encryptedHistory = [[historyPayload JSONValue] retain];
			NSString *keyURL = [encryptedHistory objectForKey:@"encryption"];
		
			NSDictionary *theKey;
			if ((theKey = [_symKeys objectForKey:keyURL]) == nil) {
				NSData *keyBundle = [Fetcher getAbsoluteURLSynchronous:keyURL];
				theKey = [self extractBulkKeyFrom:keyBundle];
				[_symKeys setValue:theKey forKey:keyURL];
			}
			
			// Do the decrypt
			NSString *plaintextHistory = [CryptoUtils decryptObject:encryptedHistory withKey:theKey];
			
			// Hmm, sometimes plaintext appears to be nil. Why?
			if (plaintextHistory != nil) {
				[userHistory setObject:plaintextHistory forKey:historyID];
			}
		}
	}
  
	// We have all the history entries, decrypted. use a transaction to put them in the database safely
	// This can easily all be moved into the Store, and just pass in both lists
	[[Store getStore] beginTransaction];
	
	// First, delete all the dead history entries.
	for (NSString* anID in userDeadHistory) {
		[[Store getStore] removeRecord: anID];
	}

	// Second, insert all the new history entries 
	for (NSString* anID in [userHistory allKeys]) {
		[[Store getStore] addHistorySet:[userHistory objectForKey:anID] withClientID:anID];
	}

	[[Store getStore] updateHistorySyncTime];
	[[Store getStore] endTransaction];
}

-(NSDictionary *) extractBulkKeyFrom:(NSData*)bulkKeyData
{
	// A bulk key response looks like:
	// {"id":"tabs","modified":1255799465.58,"payload":"{\"bulkIV\":\"<base64-encoded-IV>\",\"keyring\":{\"https:\/\/sj-weave01.services.mozilla.com\/0.5\/<user>\/storage\/keys\/pubkey\":\"<base64-encoded-key>\"}}"}
	NSString* bulkKeyString = [[NSString alloc] initWithData:bulkKeyData encoding:NSUTF8StringEncoding];
	NSDictionary *bulkKeyResponse = [bulkKeyString JSONValue];
  
	NSDictionary *payload = [[bulkKeyResponse objectForKey:@"payload"] JSONValue];
	NSDictionary *keyring = [payload objectForKey:@"keyring"];
	
	NSArray* keyEntries = [keyring allValues];
	NSData *symKey = [[NSData alloc] initWithBase64EncodedString:[keyEntries objectAtIndex:0]];
	NSData *usymKey = [CryptoUtils unwrapSymmetricKey:symKey withPrivateKey: _privateKey];
	NSDictionary *bulkEntry = [[NSDictionary dictionaryWithObjectsAndKeys:
								[[NSData alloc] initWithBase64EncodedString:[payload objectForKey:@"bulkIV"]], @"iv",
								usymKey, @"key", nil] retain];
	return bulkEntry;
}

@end

