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
 
 ***** END LICENSE BLOCK *****/

#import <Foundation/Foundation.h>
#import "Responder.h"

@interface Connection : NSObject {
	id cb;
	int pg;
	int index;
	BOOL success;
	unsigned long currentLength;
	
	NSString *user;
	NSString *pass;
	NSString *phrase;
	NSString *cluster;
	NSMutableData *responseData;
}

@property (nonatomic) BOOL success;
@property (nonatomic, retain) id cb;

@property (nonatomic, copy) NSString *user;
@property (nonatomic, copy) NSString *pass;
@property (nonatomic, copy) NSString *phrase;
@property (nonatomic, copy) NSString *cluster;

@property (nonatomic, retain) NSMutableData *responseData;

-(void) getResource:(NSURL *)url withCallback:(id <Responder>)callback andIndex:(int)i;
-(void) getResource:(NSURL *)url withCallback:(id <Responder>)callback pgIndex:(int)j andIndex:(int)i;
-(void) getRelativeResource:(NSString *)url withCallback:(id <Responder>)callback andIndex:(int)i;
-(void) getRelativeResource:(NSString *)url withCallback:(id <Responder>)callback pgIndex:(int)j andIndex:(int)i;

-(void) postTo:(NSURL *)url withData:(NSString *)data callback:(id <Responder>)callback andIndex:(int)i;
-(void) setUser:(NSString *)u password:(NSString *)p passphrase:(NSString *)ph andCluster:(NSString *)cl;

@end
