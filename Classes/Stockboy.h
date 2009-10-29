//
//  Stockboy.h
//  Weave
//
//  Created by Dan Walkowski
//

#import <Foundation/Foundation.h>

//The stockboy, a singleton, is responsible for checking to see if the user's data is fresh, and if not,
// downloading the latest info from the server and installing it in the Store.  

@interface Stockboy : NSObject 
{
  //location against which to make all weave requests for a particular user
  NSString* _cluster;
  
  //a reference to the users private key, so we don't have to keep getting it every time
  SecKeyRef _privateKey;
  
  //a dictionary of important urls and relative paths needed to retrieve things
  NSDictionary* _networkPaths;
}

//if the global is null, it makes a new Stockboy and runs him in a new thread
+ (void) restock;


@end
