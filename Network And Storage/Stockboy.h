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

// The stockboy, a singleton, is responsible for checking to see
// if the user's data is fresh, and if not, downloading the latest
// info from the server and installing it in the Store.  

@interface Stockboy : NSObject 
{
	// location against which to make all weave requests for a
	// particular user
	NSString *_cluster;
	
	// a reference to the users private key, so we don't have to
	// keep getting it every time
	SecKeyRef _privateKey;
	
	// a dictionary of symmetric keys used by each engine
	NSMutableDictionary *_symKeys;
}

// if the global is null, it makes a new Stockboy and
// runs him in a new thread
+(void) restock;

// global dictionary for finding locations of canonical weave objects
+(NSString *) urlForWeaveObject:(NSString*)name;

@end
