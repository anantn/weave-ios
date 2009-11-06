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

#import "Fetcher.h"
#import "JSON.h"
#import "Utility.h"
#import "Store.h"


@implementation Fetcher


- (Fetcher *)initWithCluster:(NSString *)clust observer:(id)obs completionMethod:(SEL)compl 
{
	self = [super init];
	
	if (self) {
		cluster = [clust retain];
		observer = [obs retain];
		completionMethod = compl;
    
		resultCode = 0;
		responseData = [[NSMutableData data] retain];
	}
	return self;
}

- (void)dealloc
{
	[cluster release];
	[observer release];
	[responseData release];
  
	[super dealloc];
}

// TODO: Add logging information to methods

// synchronous retrieval
+ (NSData *)getAbsoluteURLSynchronous:(NSString *)url
{
	// FIXME: This method should never really be called with
	// an empty url, but it does sometimes, so we check first.
	if (!url) {
		NSLog(@"Fetcher getAbsoluteURLSynchronous was called with nil URL!");
		return nil;
	} else {
		NSLog(@"Fetching %@", url);
	}
	
	NSURL *fullPath = [NSURL URLWithString:url];
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:fullPath
									cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:10];
	// add basic-auth header
	NSString *format = [NSString stringWithFormat:@"%@:%@", [[Store getStore] getUsername], [[Store getStore] getPassword]];
	NSString *utf8base64format = [[format dataUsingEncoding:NSUTF8StringEncoding] base64Encoding];
	[request addValue:[NSString stringWithFormat:@"Basic %@", utf8base64format] forHTTPHeaderField:@"Authorization"];
  
	NSURLResponse *urlResponse;
	return [NSURLConnection sendSynchronousRequest:request returningResponse:&urlResponse error:NULL];
}

// synchronous PUT
+ (NSData *)putAbsoluteURLSynchronous:(NSString *)url withData:(NSData *)data
{
	NSURL *fullPath = [NSURL URLWithString:url];
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:fullPath
									cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:10];

	// add basic-auth header
	NSString *format = [NSString stringWithFormat:@"%@:%@", [[Store getStore] getUsername] , [[Store getStore] getPassword]];
	NSString *utf8base64format = [[format dataUsingEncoding:NSUTF8StringEncoding] base64Encoding];
	[request addValue:[NSString stringWithFormat:@"Basic %@", utf8base64format] forHTTPHeaderField:@"Authorization"];
	
	// make it PUT and add body
	[request setHTTPMethod:@"PUT"];
	[request setHTTPBody:data];
	
	NSHTTPURLResponse* urlResponse;
	return [NSURLConnection sendSynchronousRequest:request returningResponse:&urlResponse error:NULL];
}

+ (NSData *)getURLSynchronous:(NSString *)url fromCluster:(NSString *)cluster
{
	if (!cluster) {
		NSLog(@"Error! No cluster set and getRelativeResource called");
		return nil;
	}
	
	NSString *full = [NSString stringWithFormat:@"%@0.5/%@/%@", cluster, [[Store getStore] getUsername], url];
	return [Fetcher getAbsoluteURLSynchronous: full];
}

+ (NSData *)putURLSynchronous:(NSString*)url fromCluster:(NSString *)cluster withData:(NSData *)data
{
	if (!cluster)  {
		NSLog(@"Error! No cluster set and getRelativeResource called");
		return nil;
	} 
	
	NSString *full = [NSString stringWithFormat:@"%@0.5/%@/%@", cluster, [[Store getStore] getUsername], url];
	return [Fetcher putAbsoluteURLSynchronous:full withData:data];
}


/* Asynchronous communication */
- (void)getAbsoluteURLResource:(NSString *)url
{
	requestURL = [url retain];
	NSURL *fullPath = [NSURL URLWithString:url];
	
	// TODO: raise exception if fullPath is nil
	NSLog(@"Request for raw input %@", url);
	NSLog(@"Request for %@", [fullPath absoluteURL]);  
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:fullPath
									cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:10];
	  
	// add basic-auth header
	NSString* format = [NSString stringWithFormat:@"%@:%@", [[Store getStore] getUsername] , [[Store getStore] getPassword]];
	NSString* utf8base64format = [[format dataUsingEncoding:NSUTF8StringEncoding] base64Encoding];
	[request addValue:[NSString stringWithFormat:@"Basic %@", utf8base64format] forHTTPHeaderField:@"Authorization"];
  
	[[NSURLConnection alloc] initWithRequest:request delegate:self];
}


-(void) getClusterRelativeURLResource:(NSString *)url 
{
	if (!cluster) {
		NSLog(@"Error! No cluster set and getRelativeResource called");
		return;
	}
	NSString *full = [NSString stringWithFormat:@"%@0.5/%@/%@", cluster, [[Store getStore] getUsername], url];
	[self getAbsoluteURLResource: full];
}




-(void) connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response 
{
	resultCode = [(NSHTTPURLResponse *)response statusCode];
	NSLog(@"Got response code %d", resultCode);
}



-(void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data 
{
	[responseData appendData:data];
}

// We get this when we are finished, so send everything we have, and the url it came from, for identification
-(void) connectionDidFinishLoading:(NSURLConnection *)connection 
{
	if (resultCode == 200 && completionMethod != nil) {
		[observer performSelector: completionMethod withObject: responseData withObject: requestURL];
	}
}

-(void) connection:(NSURLConnection *)connection didFailWithError:(NSError *)error 
{
	// call error handler on observer?
}


@end
