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
- (void) refreshKeys;
@end



@implementation Stockboy

// The singleton instance
static Stockboy* _gStockboy = nil;


//CLASS METHODS////////
+ (Stockboy*)getStockboy
{
  if (_gStockboy == nil)
    _gStockboy = [[Stockboy alloc] init];
  return _gStockboy;
}


////INSTANCE METHODS//

-(Stockboy*) init 
{
	self = [super init];
	if (self) 
  {
    cluster = nil;
    pendingDecrypts = [[NSMutableArray alloc] init];
    pendingKeyFetchers = [[NSMutableDictionary alloc] init];
    bulkKeys = [[NSMutableDictionary alloc] init];
    
    networkPaths = [[self loadPaths] retain];
    if (!networkPaths)
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
	[rc setHostName:[networkPaths objectForKey:@"Service Base URL"]];
	return ([rc remoteHostStatus] != NotReachable);
}

- (BOOL) storeIsStale
{
  //wait this is probably not right.  I think it either matches our local date or it doesn't, meaning stale?
  if ([[NSDate date] timeIntervalSince1970] - [[Store getStore] getSyncTime] > 180)  //three minutes? I made this up
  {
    return TRUE;
  }
  else return FALSE;
}

// Store an encrypted object for later decryption and storage.
-(void) addPendingDecrypt:(NSDictionary*)object storeMethod:(SEL)store
{
	//NSLog(@"Adding pending decrypt of %@", object);
	[pendingDecrypts addObject:[[PendingDecrypt alloc] initWithObject:object storeCompletion:store]];
}


// Get the cluster
// This is synchronous, since we can't make any other requests until we have it.
- (void) getCluster
{
  /* Get cluster */
	NSString *cl = [NSString stringWithFormat:[networkPaths objectForKey:@"Node Query URL"], [[Store getStore] getUsername]];
	NSLog(@"Fetching cluster from %@", cl);

	NSData* clusterData = [Fetcher getAbsoluteURLSync:cl];
  cluster = [[NSString alloc] initWithData:clusterData encoding:NSUTF8StringEncoding];

	NSLog(@"Got cluster: %@", cluster);
}  


// getPrivateKey completionMethod callback
- (void) gotPrivateKey:(NSData*)response from:(NSString*)url
{
  //convert to string here
  NSString* responseString = [[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding];
	NSDictionary *responseJSON = [responseString JSONValue];
	NSDictionary *payload = [[responseJSON valueForKey:@"payload"] JSONValue];

	// once we have the private key...
	if ([CryptoUtils decryptPrivateKey:payload withPassphrase:[[Store getStore] getPassphrase]]) 
  {
		// we're good... retrieve tabs?
		NSLog(@"Success installing private key");
		WeaveAppDelegate *app = (WeaveAppDelegate *)[[UIApplication sharedApplication] delegate];
		[app switchLoginToMain];
		[self refreshStock];
	} else {
		// things are bad... report error
		NSLog(@"Error while installing private key");
	}
}

//get the private key
- (void) getPrivateKey
{
  Fetcher* privateKeyFetcher = [[Fetcher alloc] initWithCluster:cluster observer:self completionMethod:@selector(gotPrivateKey:from:)];
  [privateKeyFetcher getClusterRelativeURLResource:[networkPaths objectForKey:@"Private Key URL"]];
}


// getBookmarks completionMethod callback
- (void) gotBookmarks:(NSData*)bookmarks from:(NSString*)URL
{
	// The bookmarks data looks like:
	// [{"id":"{021435a1-b4e6-db41-8617-c7dbc11eb692}1","parentid":"menu","modified":1254504753.42,"payload":"{\"encryption\":\"https:\/\/sj-weave01.services.mozilla.com\/0.5\/michaelrhanson\/storage\/crypto\/bookmarks\",\"ciphertext\":\"WS5+4g7Ppe9IDkwKfvlfEXbz\/zHfFQp+lYdffx2NFe1eNj\/QGSZj4XavuPE69nh+phIfYqqdEzPnQXxrMa6jTaGlkUir5\/v7gDPBEvLbj7SOuzM1hH8pakiOLcio3wtlbBHpSoVcEeNl7he5Oi6dv8EHwvqme3hJwkpRyP37N9w1E3iW+xmR0epmHrC5TgyJV6lt2wr90QwLo2mq3tyrCcV+6wB\/v98Na46aI4GoA3Gqexxqi+Mz2LS5+Mw0DwAiURiTRpCJ2hCat77IRKNBvVlQrsFdn9Xn2H5CD9IMtBhrtzeC+qOh4Xx4XTXTTrrUTEKTubfzwSsTB760X\/NIN1NnEHPwKGrUHf4rLP00UBWcxEiGlhzJdq4BrqMqO5fRDsOZqiP67ygIB1K+8GKpRm58mgPPpAjsP893k4YMaVFUY8TMOTVFMuit1sPoBFiiNiI9xYmet7p\/8K6JU\/CvC\/y1dzQVG21jVfxI\/tXOHXMCBeTKKqABKcFZsuI5cCoX+W+SayQ19W+EnAAxMXLUFKAAWXDuVbu30hCCGGBpw+gN7TmQU3cLa2J18kM6vBKM6BdYa1O9pddnMvudR2mOwtNYNdKGr0ZpasIcJWwO3HG7L8M+EfLAKaOMMYClmwqrkeGEQLF3HFvxuxntRqJ0nQ==\"}"},{"id":"{021435a1-b4e6-db41-8617-c7dbc11eb692}2","parentid":"menu","modified":1254504753.42,"payload":"{\"encryption\":\"https:\/\/sj-weave01.services.mozilla.com\/0.5\/michaelrhanson\/storage\/crypto\/bookmarks\",\"ciphertext\":\"WS5+4g7Ppe9IDkwKfvlfETQjdDfigohUK4bVwbMctXujfQ1CFoAJvSY8nBo9lfHcLnnnjxYQN1IFkGf+87NwugyhHmOfrAOJ55zUsV0A41j4oaY9COm2eDx5ysGBmh0ogXuaQu5LMCUZq492iyTrjiNUS7ldDrZebCOdWyEeqZVZJEFinwQh9evCRBTW1oXo32r8NcUofJHKKYg9DJErq8fVqo6CzFwkjdJD5fOLZkwZjlYIdIsuW0Y3LU+g95nJCn3E8sfd7jrL3QFCUTIZhRpH0LAqPiMbxEpxZS72mjOxuJCnG2QAKouyZcj9FMsDEpAqmZUyTCd8e0CML0lgIactkrAc43y7\/gncSQ2RJp8q7MB3pzfydBxQpnYppJNnakmPJbaUPLsScu70j6TCnW6vfR+fkPwFw1OwUZrLBWUFGcrn7DvOU0ozIkS2vs8q9nq+8MQoMWAqWahtWiF0KIJNqzMSsoflq\/th7+3lVbusruSU+9CkvIXFIyZztPTKBim1a+WKtEKiE8k2jbbY49MfYS9yW66b7ptdCAEwnImglRtNs"}]
	
	NSLog(@"Got bookmarks");
  NSString* bookmarksString = [[NSString alloc] initWithData:bookmarks encoding:NSUTF8StringEncoding];

	NSDictionary *obj = [bookmarksString JSONValue];
	NSEnumerator *iter = [obj objectEnumerator];
	while (obj = [iter nextObject]) {

		// A bookmark deletion is signaled with an empty string
		NSString *payloadStr = [obj valueForKey:@"payload"];
		if (payloadStr == nil || [payloadStr length] == 0)
		{
			// NSLog(@"Got an empty bookmark: %@", bookmarksString);
		}
		else 
		{
			[self addPendingDecrypt:obj storeMethod:@selector(addBookmarkRecord:withID:)];
		}
	}
	[self refreshKeys];
}

//get the bookmarks
- (void) getBookmarks
{
	[Fetcher ensureClusterRelativeFetcher:cluster forURL:[networkPaths objectForKey:@"Bookmarks URL"] 
		observer:self completionMethod:@selector(gotBookmarks:from:)];
}


// getHistory completionMethod callback
- (void) gotHistory:(NSData*)history from:(NSString*)URL
{
	NSLog(@"Got history data: processing it");
  NSString* historyString = [[NSString alloc] initWithData:history encoding:NSUTF8StringEncoding];

	NSDictionary *obj = [historyString JSONValue];
	NSEnumerator *iter = [obj objectEnumerator];
	while (obj = [iter nextObject]) 
  {
		[self addPendingDecrypt:obj storeMethod:@selector(addHistoryRecord:withID:)];
	}
	[self refreshKeys];
}

//get the history
- (void) getHistory
{
	[Fetcher ensureClusterRelativeFetcher:cluster forURL:[networkPaths objectForKey:@"History URL"] 
		observer:self completionMethod:@selector(gotHistory:from:)];
}

// completionMethod callback for getTabs
- (void) gotTabs:(NSData*)tabs from:(NSString*)URL
{
	NSLog(@"Got tab data");
  NSString* tabsString = [[NSString alloc] initWithData:tabs encoding:NSUTF8StringEncoding];

	NSDictionary *obj = [tabsString JSONValue];
	NSEnumerator *iter = [obj objectEnumerator];
	while (obj = [iter nextObject]) 
  {
		[self addPendingDecrypt:obj storeMethod:@selector(addTab:withID:)];
	}
	[self refreshKeys];
}


//get the tabs
- (void) getTabs
{
	[Fetcher ensureClusterRelativeFetcher:cluster forURL:[networkPaths objectForKey:@"Tabs URL"] 
		observer:self completionMethod:@selector(gotTabs:from:)];
}


- (void) refreshStock
{
  if (!networkPaths)
  {
    NSLog(@"Unable to make network requests, url definitions unavailable");
    return;
  }
  
  //check for connectivity, get the cluster, check freshness, then get each of the datasets
  if ([self hasConnectivity])
  {
    if (cluster == nil) {
			[self getCluster];  //this one is synchronous
		}
    
    if ([CryptoUtils _getKeyNamed:PRIV_KEY_NAME] == nil)
    {
      // still need the private key; can't do anything else until we have it
      [self getPrivateKey];
    } else {
			// This is ugly: we shouldn't to perform this check here.
			WeaveAppDelegate *app = (WeaveAppDelegate *)[[UIApplication sharedApplication] delegate];
			[app switchLoginToMain];
		}
    
    if ([self storeIsStale])
    {
				// the rest of these can all be done asynch, with multiple connections
				[self getBookmarks];
				[self getHistory];
				[self getTabs];
    }
    
  }
  else 
  {
    {
      UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Network" message:@"Weave cannot update" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
      [alert show];
      [alert release];
    }
  }
}


//callback used by refreshKeys
- (void) gotBulkKey:(NSData*)bulkKey from:(NSString*)URL
{
	// A bulk key response looks like:
	// {"id":"tabs","modified":1255799465.58,"payload":"{\"bulkIV\":\"<base64-encoded-IV>\",\"keyring\":{\"https:\/\/sj-weave01.services.mozilla.com\/0.5\/<user>\/storage\/keys\/pubkey\":\"<base64-encoded-key>\"}}"}
  
  NSString* bulkKeyString = [[NSString alloc] initWithData:bulkKey encoding:NSUTF8StringEncoding];

	NSLog(@"Got bulk key %@", bulkKeyString);

	NSDictionary *bulkKeyResponse = [bulkKeyString JSONValue];
	NSDictionary *payload = [[bulkKeyResponse objectForKey:@"payload"] JSONValue];

	NSDictionary *keyring = [payload objectForKey:@"keyring"];
	
	// for each item on the keyring...
	NSEnumerator *enumerator = [keyring keyEnumerator];
	id key;
	while ((key = [enumerator nextObject])) 
  {
		NSString *keyValue = [keyring objectForKey:key];
		NSData *symKey = [[NSData alloc] initWithBase64EncodedString:keyValue];
		NSData *usymKey = [CryptoUtils unwrapSymmetricKey:symKey];

		NSDictionary *bulkEntry = [NSDictionary dictionaryWithObjectsAndKeys:
			[[NSData alloc] initWithBase64EncodedString:[payload objectForKey:@"bulkIV"]], @"iv",
			usymKey, @"key", nil];
		[bulkKeys setObject:bulkEntry forKey:URL];

		NSLog(@"Installed key for %@", URL);
	}

	// And now see if anybody is ready to decrypt
	[self refreshKeys];
}



- (void) refreshKeys
{
	// check for pending decrypts that don't have a key fetcher already in flight;
	// initiate a new fetcher for each of them
	NSEnumerator *iter = [pendingDecrypts objectEnumerator];
	NSMutableArray *deleteArray = [NSMutableArray arrayWithCapacity:[pendingDecrypts count]];
	PendingDecrypt *pendingDecrypt;
	while (pendingDecrypt = [iter nextObject]) {
		NSDictionary *obj = [pendingDecrypt getEncryptedObject];
		// NSLog(@"refreshing keys for %@", obj);
		NSDictionary *wbo = [[obj objectForKey:@"payload"] JSONValue];
		NSString *url = [wbo objectForKey:@"encryption"];

		// If we have a key ready to go, decrypt.
		// Otherwise start downloading that key.
		NSDictionary *usymkey = [bulkKeys objectForKey:url];
		if (usymkey != nil)
		{
			// Do the decrypt
			NSString *plainText = [CryptoUtils decryptObject:wbo withKey:usymkey];
			SEL selector = [pendingDecrypt getStoreCompletion];
			[[Store getStore] performSelector:selector withObject:plainText withObject:[obj objectForKey:@"id"]];
			[deleteArray addObject:pendingDecrypt];
		}
		else
		{
			Fetcher *f = [pendingKeyFetchers objectForKey:url];
			if (f == nil) {
				// NSLog(@"Key %@ isn't in the pending key list: fetching it", url);
				Fetcher* keyFetcher = [[Fetcher alloc] initWithCluster:cluster observer:self completionMethod:@selector(gotBulkKey:from:)];
				[keyFetcher getAbsoluteURLResource:url];
				[pendingKeyFetchers setValue:keyFetcher forKey:url];
			} else {
				// NSLog(@"Key %@ is already in the pending key list.", url);		
			}
		}
	}

	[pendingDecrypts removeObjectsInArray:deleteArray];
}

 @end


@implementation PendingDecrypt

-(PendingDecrypt*) initWithObject:(NSDictionary *)object storeCompletion:(SEL)store
{
	self = [super init];
	if (self) 
  {
		encryptedObject = [object retain];
		storeCompletion = store;
	}
	return self;
}
- (NSDictionary *)getEncryptedObject
{
	return encryptedObject;
}
- (SEL)getStoreCompletion
{
	return storeCompletion;
}
@end