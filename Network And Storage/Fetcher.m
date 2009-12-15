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


@implementation Fetcher

// TODO: Add logging information to methods

// synchronous GET
+ (NSData *)getAbsoluteURLSynchronous:(NSString *)url withUser:(NSString*)user andPassword:(NSString*)password
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
	NSString *format = [NSString stringWithFormat:@"%@:%@", user, password];
	NSString *utf8base64format = [[format dataUsingEncoding:NSUTF8StringEncoding] base64Encoding];
	[request addValue:[NSString stringWithFormat:@"Basic %@", utf8base64format] forHTTPHeaderField:@"Authorization"];
  
	NSURLResponse *urlResponse;
	return [NSURLConnection sendSynchronousRequest:request returningResponse:&urlResponse error:NULL];
}

// synchronous PUT
+ (NSData *)putAbsoluteURLSynchronous:(NSString *)url withUser:(NSString*)user andPassword:(NSString*)password andData:(NSData *)data
{
	NSURL *fullPath = [NSURL URLWithString:url];
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:fullPath
									cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:10];

	// add basic-auth header
	NSString *format = [NSString stringWithFormat:@"%@:%@", user, password];
	NSString *utf8base64format = [[format dataUsingEncoding:NSUTF8StringEncoding] base64Encoding];
	[request addValue:[NSString stringWithFormat:@"Basic %@", utf8base64format] forHTTPHeaderField:@"Authorization"];
	
	// make it PUT and add body
	[request setHTTPMethod:@"PUT"];
	[request setHTTPBody:data];
	
	NSHTTPURLResponse* urlResponse;
	return [NSURLConnection sendSynchronousRequest:request returningResponse:&urlResponse error:NULL];
}

+ (NSData *)getURLSynchronous:(NSString *)url fromCluster:(NSString *)cluster withUser:(NSString*)user andPassword:(NSString*)password
{
	if (!cluster) {
		NSLog(@"Error! No cluster set and getRelativeResource called");
		return nil;
	}
	
	NSString *full = [NSString stringWithFormat:@"%@1.0/%@/%@", cluster, user, url];
	return [Fetcher getAbsoluteURLSynchronous: full withUser:user andPassword:password];
}

+ (NSData *)putURLSynchronous:(NSString*)url toCluster:(NSString *)cluster withUser:(NSString*)user andPassword:(NSString*)password andData:(NSData *)data
{
	if (!cluster)  {
		NSLog(@"Error! No cluster set and getRelativeResource called");
		return nil;
	} 
	
	NSString *full = [NSString stringWithFormat:@"%@1.0/%@/%@", cluster, user, url];
	return [Fetcher putAbsoluteURLSynchronous:full withUser:user andPassword:password andData:data];
}



@end
