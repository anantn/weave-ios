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
	Dan Walkowski <dan.walkowski@mozilla.com>

 ***** END LICENSE BLOCK *****/

#import <Foundation/Foundation.h>


@interface Fetcher : NSObject 
{
}
  //synchronous wrapper for public uri data retrieval with timeout, not requiring basic auth or cluster.
+ (NSData *)getPublicURL:(NSString *)url;


// class utility method for synchronous fetching (and PUT),
// used for the cluster, which must be gotten before we can do anything else
+ (NSData *)getAbsoluteURLSynchronous:(NSString *)url withUser:(NSString*)user andPassword:(NSString*)password;
+ (NSData *)putAbsoluteURLSynchronous:(NSString *)url withUser:(NSString*)user andPassword:(NSString*)password andData:(NSData *)data;

+ (NSData *)getURLSynchronous:(NSString *)url fromCluster:(NSString *)cluster withUser:(NSString*)user andPassword:(NSString*)password;
+ (NSData *)putURLSynchronous:(NSString *)url toCluster:(NSString *)cluster withUser:(NSString*)user andPassword:(NSString*)password andData:(NSData *)data;

@end

