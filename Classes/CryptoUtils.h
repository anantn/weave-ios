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

#import	<CommonCrypto/CommonHMAC.h>
#import	<CommonCrypto/CommonDigest.h>
#import	<CommonCrypto/CommonCryptor.h>
#import <Security/Security.h>

#import "Utility.h"

#define KEY_SIZE			2048
#define PRIV_KEY_NAME		@"private"


@interface CryptoUtils : NSObject

// returns true if succesful
+ (BOOL)fetchAndInstallPrivateKeyFor:passphrase;
+ (BOOL)fetchAndUpdateClients;

+ (BOOL)decryptPrivateKey:(NSDictionary *)payload withPassphrase:(NSString*)passphrase;
+ (NSData *)unwrapSymmetricKey:(NSData *)symKey withPrivateKey:(SecKeyRef)privateKey;
+ (NSString*)decryptObject:(NSDictionary*)object withKey:(NSDictionary*)bulkKey;
+ (SecKeyRef)_getKeyNamed:(NSString *)keyName;

@end

@interface NSData (AES)
- (NSData *) AESencryptWithKey:(NSData *)key andIV:(NSData *)iv;
- (NSData *) AESdecryptWithKey:(NSData *)key andIV:(NSData *)iv;
@end

int PKCS5_PBKDF2_HMAC_SHA1(const char *pass, int passlen,
                           const unsigned char *salt, int saltlen, int iter,
                           int keylen, unsigned char *out);
