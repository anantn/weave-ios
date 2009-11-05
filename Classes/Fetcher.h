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

#import <Foundation/Foundation.h>


@interface Fetcher : NSObject 
{
	id observer;  // which object to notify
	SEL completionMethod;  // called with the complete response data and the request URL
	
	int resultCode;
	
	NSString *cluster;
	
	// storage for response data
	NSMutableData *responseData;  
	NSString *requestURL;
}

// class utility method for synchronous fetching (and PUT),
// used for the cluster, which must be gotten before we can do anything else
+ (NSData *)getAbsoluteURLSynchronous:(NSString *)url;
+ (NSData *)getURLSynchronous:(NSString *)url fromCluster:(NSString *)cluster;
+ (NSData *)putURLSynchronous:(NSString *)url fromCluster:(NSString *)cluster withData:(NSData *)data;

// Note that the completion method must take two arguments, an NSData and an NSString
// The first is the responseData, the second is the originating URL
-(Fetcher *) initWithCluster:(NSString *)cluster observer:(id)obs completionMethod:(SEL)compl;

-(void) getAbsoluteURLResource:(NSString *)url;
-(void) getClusterRelativeURLResource:(NSString *)url;

@end

