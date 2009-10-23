//
//  Stockboy.h
//  Weave
//
//  Created by Dan Walkowski
//

#import <Foundation/Foundation.h>

//The stockboy, also a singleton, is responsible for checking to see if the user's data is fresh, and if not,
// downloading the latest info from the server and installing it in the Store.  

@interface Stockboy : NSObject 
{
  //location against which to make all weave requests for a particular user
  NSString* cluster;

  // list of pending decrypts (JSON objects)
  NSMutableArray *pendingDecrypts;

  // dictionary of Fetchers that are currently retrieving bulk keys
  // keyed on key URL
  NSMutableDictionary *pendingKeyFetchers;
	
	// The bulk keys we've already retrieved, keyed on URL
  NSMutableDictionary *bulkKeys;
  
  //a dictionary of important urls and relative paths needed to retrieve things
  NSDictionary* networkPaths;
}

//if the global is null, it makes a new singleton Stockboy
+ (Stockboy*) getStockboy;

//called on startup, and thereafter as requested
- (void) refreshStock;

@end

@interface PendingDecrypt : NSObject
{
	NSDictionary *encryptedObject;
	SEL storeCompletion;
}

-(PendingDecrypt*) initWithObject:(NSDictionary*)object storeCompletion:(SEL)store;
- (NSDictionary *)getEncryptedObject;
- (SEL )getStoreCompletion;
@end