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

#define GOT_PRIV_KEY		0
#define GOT_BULK_KEY		1

#define CRYPTO_DONE_FAIL	0
#define CRYPTO_DONE_INIT	1
#define CRYPTO_DONE_LAST	2

#define KEY_SIZE			2048
#define PRIV_KEY_NAME		@"private"

@class Connection, Service;

@interface Crypto : NSObject <Responder> {
	SEL select;
	Service *serv;
	NSString *curBulk;
	NSMutableArray *wbos;
	NSMutableDictionary *bulk;
}

@property (nonatomic, retain) Service *serv;
@property (nonatomic, retain) NSString *curBulk;
@property (nonatomic, retain) NSMutableArray *wbos;
@property (nonatomic, retain) NSMutableDictionary *bulk;

-(void) setSelector:(SEL)selector;
-(void) decryptWBO:(NSDictionary *)record;

-(Crypto *) initWithService:(Service *)s;
-(NSData *) unwrapSymmetricKey:(NSData *)symKey;

/* Connection responder */
-(void) successWithString:(NSString *)response andIndex:(int)i;
-(void) failureWithError:(NSError *)error andIndex:(int)i;

@end

@interface NSData (AES)

-(NSData *) AESencryptWithKey:(NSData *)key andIV:(NSData *)iv;
-(NSData *) AESdecryptWithKey:(NSData *)key andIV:(NSData *)iv;

@end
