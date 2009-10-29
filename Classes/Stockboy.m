//
//  Stockboy.m
//  Weave
//
//  Created by Dan Walkowski
//

#import "Stockboy.h"
#import "Store.h"
#import "Fetcher.h"
#import "Reachability.h"
#import "Utility.h"
#import "WeaveAppDelegate.h"
#import "CryptoUtils.h"

#import "NSString+SBJSON.h"



@interface Stockboy (PRIVATE)
- (NSDictionary*) loadPaths;
- (void) getCluster;
- (NSDictionary*) extractBulkKeyFrom:(NSData*)bulkKeyData;


//these should probably return something useful
- (void) updateTabs;
- (void) updateBookmarks;
- (void) updateHistory;
@end



@implementation Stockboy

// The singleton instance
static Stockboy* _gStockboy = nil;


//CLASS METHODS////////
+ (void)restock
{
  if (_gStockboy == nil)
  {
    _gStockboy = (id)1; //minimize race condition
    _gStockboy = [[Stockboy alloc] init];
    
    NSThread* keyThread = [[NSThread alloc] initWithTarget:_gStockboy selector:@selector(restockEverything) object:nil];
    [keyThread start];
  }
}


////INSTANCE METHODS//

-(Stockboy*) init 
{
	self = [super init];
	if (self) 
  {
    _cluster = nil;
    
    //cache a copy of this for speed.  we were looking it up for every decrypt
    _privateKey = [CryptoUtils _getKeyNamed:PRIV_KEY_NAME];
    
    _networkPaths = [[self loadPaths] retain];
    if (!_networkPaths)
    {
      //bad, we won't be able to do anything
      NSLog(@"Could not load url definitions! Missing plist file?");
    }
	}
	return self;
}


- (NSDictionary*) loadPaths
{
  NSString *error = nil;
  NSPropertyListFormat format;
  NSString *pathtoPaths = [[NSBundle mainBundle] pathForResource:@"NetworkPaths" ofType:@"plist"];
  NSData *pathsXML = [[NSFileManager defaultManager] contentsAtPath:pathtoPaths];
  NSDictionary *thePaths = (NSDictionary *)[NSPropertyListSerialization
                                              propertyListFromData:pathsXML
                                              mutabilityOption:NSPropertyListMutableContainersAndLeaves
                                              format:&format errorDescription:&error];
  if (!thePaths) 
  {
    NSLog(@"%@", error);
    [error release];
    return nil;
  }
  
  return thePaths;
}


- (BOOL) hasConnectivity
{
 	Reachability* rc = [Reachability sharedReachability];
	[rc setHostName:[_networkPaths objectForKey:@"Service Base URL"]];
	return ([rc remoteHostStatus] != NotReachable);
}


// Get the cluster
// This is synchronous, since we can't make any other requests until we have it.
- (void) getCluster
{
  // Get cluster
	NSString *cl = [NSString stringWithFormat:[_networkPaths objectForKey:@"Node Query URL"], [[Store getStore] getUsername]];  
	NSData* clusterData = [Fetcher getAbsoluteURLSynchronous:cl];
  _cluster = [[NSString alloc] initWithData:clusterData encoding:NSUTF8StringEncoding];
}  



- (void) restockEverything
{
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

  if ([self hasConnectivity] && _networkPaths && _privateKey)
  {
    [self getCluster];
    
    //MISSING: check for cluster and private key and bail if we don't have them
    [self updateTabs];
    [self updateBookmarks];
    [self updateHistory];
  }
  
  _gStockboy = nil;
  [pool drain];
}

- (void) updateTabs
{  
  //Don't need to check timestamp.  We always get all the tabs, regardless of any timestamp.  
  
  //synchronous request.  we are running in a separate thread, so it's ok to block.
  NSData* tabs = [Fetcher getURLSynchronous:[_networkPaths objectForKey:@"Tabs URL"] fromCluster:_cluster];
  if (tabs == nil) return; //better error handling
  
  //this will hold all the resultant decrypted tabs
  NSMutableDictionary* userTabs = [NSMutableDictionary dictionary];
  
  //This bit of primitive parsing relies on the data coming as a dictionary of dictionaries. beware of 'does not understand' exceptions
  NSString* tabsString = [[NSString alloc] initWithData:tabs encoding:NSUTF8StringEncoding];
	NSDictionary* tabsDict = [tabsString JSONValue];
	NSEnumerator* tabIterator = [tabsDict objectEnumerator];
  
  NSDictionary* tabBundle;
	while (tabBundle = [tabIterator nextObject]) 
  {
    //get the interesting bits out of the bundle    
    NSDictionary *encryptedTab = [[tabBundle objectForKey:@"payload"] JSONValue];
		NSString *keyURL = [tabBundle objectForKey:@"encryption"];
    NSString *tabID = [encryptedTab objectForKey:@"id"];
    
    
		//get the bulk key for this wbo    
    NSData* keyBundle = [Fetcher getAbsoluteURLSynchronous: keyURL];
    NSDictionary* theKey = [self extractBulkKeyFrom:keyBundle];

    // Do the decrypt and save the result keyed by id
    [userTabs setObject: [CryptoUtils decryptObject:encryptedTab withKey:theKey] forKey: tabID];
	}
  
  //ok, now we have all the tabs, decrypted.  use a transaction to put them in the database safely
  
  //MISSING: OPEN SQL TRANSACTION IMMEDIATE
  
  //First, delete all the existing tabs.
  //MISSING: <some sql goes here to delete all the tabs>
  
  //Second, insert all the new tabs 
  for (NSString* anID in [userTabs allKeys])
  {
    [[Store getStore] addTab:[userTabs objectForKey:anID] withID:anID];
  }

  //MISSING: CLOSE SQL TRANSACTION IMMEDIATE
}


- (void) updateBookmarks
{
  //synchronous request.  we are running in a separate thread, so it's ok to block.
  NSString* bmarksURL = [NSString stringWithFormat:[_networkPaths objectForKey:@"Bookmarks Update URL"], [[Store getStore] getSyncTime]];
                       
  NSData* bmarks = [Fetcher getURLSynchronous:bmarksURL fromCluster:_cluster];
  if (bmarks == nil) return; //better error handling
  
  //this will hold all the resultant decrypted bookmarks that need to be added
  NSMutableDictionary* userBmarks = [NSMutableDictionary dictionary];

  //this will hold all the resultant decrypted bookmarks that need to be deleted
  NSMutableDictionary* userDeadBmarks = [NSMutableDictionary dictionary];

  //unpack the bookmarks
  NSString* bmarksString = [[NSString alloc] initWithData:bmarks encoding:NSUTF8StringEncoding];
  NSDictionary *bmarksDict = [bmarksString JSONValue];
  NSEnumerator *bmarkIterator = [bmarksDict objectEnumerator];
	
  NSDictionary* bmarkBundle;
  while (bmarkBundle = [bmarkIterator nextObject]) 
  {
    NSDictionary *encryptedBmark = [[bmarkBundle objectForKey:@"payload"] JSONValue];
		NSString *keyURL = [bmarkBundle objectForKey:@"encryption"];
    NSString *bmarkID = [encryptedBmark objectForKey:@"id"];
    
    
    //get the bulk key for this wbo    
    NSData* keyBundle = [Fetcher getAbsoluteURLSynchronous: keyURL];
    NSDictionary* theKey = [self extractBulkKeyFrom:keyBundle];
    
    // Do the decrypt
    NSString* plaintextBmark = [CryptoUtils decryptObject:encryptedBmark withKey:theKey];
    if (plaintextBmark == nil || [plaintextBmark length] == 0)
    {
      [userDeadBmarks setObject:plaintextBmark forKey:bmarkID];
    }
    else
    {
      [userBmarks setObject:plaintextBmark forKey: bmarkID];
    }
  }
  
  //We have all the bookmarks, decrypted.  use a transaction to put them in the database safely
  
  //MISSING: OPEN SQL TRANSACTION IMMEDIATE
  
  //First, delete all the dead bookmarks.
  for (NSString* anID in [userDeadBmarks allKeys])
  {
    //MISSING: <some code goes here to delete the bookmark>
    //[Store getStore] deleteBookmarkID: anID]
  }
  
  //Second, insert all the new bookmarks 
  for (NSString* anID in [userBmarks allKeys])
  {
    [[Store getStore] addBookmarkRecord:[userBmarks objectForKey:anID] withID:anID];
  }
  
  //MISSING: CLOSE SQL TRANSACTION IMMEDIATE
  
}

- (void) updateHistory
{
  //synchronous request.  we are running in a separate thread, so it's ok to block.
  NSString* historyURL = [NSString stringWithFormat:[_networkPaths objectForKey:@"History Update URL"], [[Store getStore] getSyncTime]];
  
  NSData* history = [Fetcher getURLSynchronous:historyURL fromCluster:_cluster];
  if (history == nil) return; //better error handling
  
  //this will hold all the resultant decrypted bookmarks that need to be added
  NSMutableDictionary* userHistory = [NSMutableDictionary dictionary];
  
  //this will hold all the resultant decrypted bookmarks that need to be deleted
  NSMutableDictionary* userDeadHistory = [NSMutableDictionary dictionary];
  
  //unpack the bookmarks
  NSString* historyString = [[NSString alloc] initWithData:history encoding:NSUTF8StringEncoding];
  NSDictionary *historyDict = [historyString JSONValue];
  NSEnumerator *historyIterator = [historyDict objectEnumerator];
	
  NSDictionary* historyBundle;
  while (historyBundle = [historyIterator nextObject]) 
  {
    NSDictionary *encryptedHistory = [[historyBundle objectForKey:@"payload"] JSONValue];
		NSString *keyURL = [historyBundle objectForKey:@"encryption"];
    NSString *historyID = [encryptedHistory objectForKey:@"id"];
    
    
    //get the bulk key for this wbo    
    NSData* keyBundle = [Fetcher getAbsoluteURLSynchronous: keyURL];
    NSDictionary* theKey = [self extractBulkKeyFrom:keyBundle];
    
    // Do the decrypt
    NSString* plaintextHistory = [CryptoUtils decryptObject:encryptedHistory withKey:theKey];
    if (plaintextHistory == nil || [plaintextHistory length] == 0)
    {
      [userDeadHistory setObject:plaintextHistory forKey:historyID];
    }
    else
    {
      [userHistory setObject:plaintextHistory forKey: historyID];
    }
  }
  
  //We have all the history entries, decrypted.  use a transaction to put them in the database safely
  
  //MISSING: OPEN SQL TRANSACTION IMMEDIATE
  
  //First, delete all the dead history entries.
  for (NSString* anID in [userDeadHistory allKeys])
  {
    //MISSING: <some code goes here to delete the bookmark>
    //[Store getStore] deleteHistoryID: anID]
  }
  
  //Second, insert all the new history entries 
  for (NSString* anID in [userHistory allKeys])
  {
    [[Store getStore] addHistoryRecord:[userHistory objectForKey:anID] withID:anID];
  }
  
  //MISSING: CLOSE SQL TRANSACTION IMMEDIATE
  
}




//callback used by refreshKeys
- (NSDictionary*) extractBulkKeyFrom:(NSData*)bulkKeyData
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



//    if ([CryptoUtils _getKeyNamed:PRIV_KEY_NAME] == nil)



//  Fetcher* privateKeyFetcher = [[Fetcher alloc] initWithCluster:_cluster observer:self completionMethod:@selector(gotPrivateKey:from:)];
//  [privateKeyFetcher getClusterRelativeURLResource:[_networkPaths objectForKey:@"Private Key URL"]];

//  //convert to string here
//  NSString* responseString = [[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding];
//	NSDictionary *responseJSON = [responseString JSONValue];
//	NSDictionary *payload = [[responseJSON valueForKey:@"payload"] JSONValue];
//
//	// once we have the private key...
//	if ([CryptoUtils decryptPrivateKey:payload withPassphrase:[[Store getStore] getPassphrase]]) 
//  {
//		// we're good... retrieve tabs?
//		NSLog(@"Success installing private key");
//		WeaveAppDelegate *app = (WeaveAppDelegate *)[[UIApplication sharedApplication] delegate];
//		[app switchLoginToMain];
//		[self refreshStock];
//	} else {
//		// things are bad... report error
//		NSLog(@"Error while installing private key");
//	}



