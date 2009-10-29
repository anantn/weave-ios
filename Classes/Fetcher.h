//
//  Fetcher.h
//  Weave
//
//  Created by Dan Walkowski
//

#import <Foundation/Foundation.h>


@interface Fetcher : NSObject 
{
	id observer;  //which object to notify
	SEL completionMethod;  //called with the complete response data and the request URL
	
	int resultCode;
	
	NSString* cluster;
	
	//storage for response data
	NSMutableData *responseData;  
	NSString *requestURL;
}

//class utility method for synchronous fetching, used for the cluster, which must be gotten before we can do anything else
+ (NSData*) getAbsoluteURLSynchronous:(NSString*)url;
+ (NSData*) getURLSynchronous:(NSString*)url fromCluster:(NSString*)cluster;

// class method to create a fetcher for the given cluster and URL; if one is already underway,
// does nothing.
+(void) ensureClusterRelativeFetcher:(NSString*)cluster forURL:(NSString*)url observer:(id)obs completionMethod:(SEL)compl;

//Note that the completion method must take two arguments, an NSData and an NSString
// The first is the responseData, the second is the originating URL
-(Fetcher *) initWithCluster:(NSString*)clust observer:(id)obs completionMethod:(SEL)compl;

-(void) getAbsoluteURLResource:(NSString*)url;
-(void) getClusterRelativeURLResource:(NSString*)url;

@end

