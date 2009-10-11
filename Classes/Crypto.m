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

#import "Crypto.h"
#import	<CommonCrypto/CommonHMAC.h>
#import	<CommonCrypto/CommonDigest.h>
#import	<CommonCrypto/CommonCryptor.h>
#import <Security/Security.h>

#import "Store.h"
#import "Service.h"
#import "Utility.h"
#import "Connection.h"

@implementation Crypto

@synthesize serv, curBulk, bulk, wbos;

-(Crypto *) initWithService:(Service *)s {
	self = [super init];
	
	if (self) {
		self.serv = s;
		self.curBulk = nil;
		self.wbos = [[NSMutableArray alloc] init];
		self.bulk = [[NSMutableDictionary alloc] init];
	}
	
	return self;
}

/* Private Crypto functions BEGIN */

int PKCS5_PBKDF2_HMAC_SHA1(const char *pass, int passlen,
						   const unsigned char *salt, int saltlen, int iter,
						   int keylen, unsigned char *out) {
	unsigned char digtmp[CC_SHA1_DIGEST_LENGTH], *p, itmp[4];
	int cplen, j, k, tkeylen;
	unsigned long i = 1;
	CCHmacContext hctx;
	p = out;
	tkeylen = keylen;
	if(!pass) passlen = 0;
	else if(passlen == -1) passlen = strlen(pass);
	while(tkeylen) {
		if(tkeylen > CC_SHA1_DIGEST_LENGTH) cplen = CC_SHA1_DIGEST_LENGTH;
		else cplen = tkeylen;
		itmp[0] = (unsigned char)((i >> 24) & 0xff);
		itmp[1] = (unsigned char)((i >> 16) & 0xff);
		itmp[2] = (unsigned char)((i >> 8) & 0xff);
		itmp[3] = (unsigned char)(i & 0xff);
		CCHmacInit(&hctx, kCCHmacAlgSHA1, pass, passlen);
		CCHmacUpdate(&hctx, salt, saltlen);
		CCHmacUpdate(&hctx, itmp, 4);
		CCHmacFinal(&hctx, digtmp);
		memcpy(p, digtmp, cplen);
		for(j = 1; j < iter; j++) {
			CCHmac(kCCHmacAlgSHA1, pass, passlen, digtmp, CC_SHA1_DIGEST_LENGTH, digtmp);
			for(k = 0; k < cplen; k++) p[k] ^= digtmp[k];
		}
		tkeylen-= cplen;
		i++;
		p+= cplen;
	}
	return 1;
}

- (BOOL)_installKeyData:(NSData *)keyData name:(NSString *)keyName label:(NSData *)keyAppLabel private:(BOOL)isPrivate
{
    BOOL            result;
    OSStatus        err;
    NSData *        keyTagData;
    CFTypeRef       keyClass;
    CFBooleanRef    kBoolToCF[2] = { kCFBooleanFalse, kCFBooleanTrue };
	
    result = NO;
    keyTagData = [keyName dataUsingEncoding:NSUTF8StringEncoding];
    assert(keyTagData != nil);
	
    if (isPrivate) {
        keyClass = kSecAttrKeyClassPrivate;
    } else {
        keyClass = kSecAttrKeyClassPublic;
    }
    
    err = SecItemAdd((CFDictionaryRef)
			[NSDictionary dictionaryWithObjectsAndKeys:
				(id)
				kSecClassKey,                   kSecClass,
				kSecAttrKeyTypeRSA,             kSecAttrKeyType, 
				keyTagData,                     kSecAttrApplicationTag,
				keyAppLabel,                    kSecAttrApplicationLabel,
				keyClass,                       kSecAttrKeyClass, 
				keyData,                        kSecValueData,
				[NSNumber numberWithInt:KEY_SIZE],  kSecAttrKeySizeInBits,
				[NSNumber numberWithInt:KEY_SIZE],  kSecAttrEffectiveKeySize,
				kBoolToCF[isPrivate],           kSecAttrCanDerive,
				kBoolToCF[!isPrivate],          kSecAttrCanEncrypt,
				kBoolToCF[isPrivate],           kSecAttrCanDecrypt,
				kBoolToCF[!isPrivate],          kSecAttrCanVerify,
				kBoolToCF[isPrivate],           kSecAttrCanSign,
				kBoolToCF[!isPrivate],          kSecAttrCanWrap,
				kBoolToCF[isPrivate],           kSecAttrCanUnwrap,
				nil
			],
			NULL
	);
    if (err == noErr) {
        NSLog(@"added key %@ with data %@", keyName, [keyData base64Encoding]);
        result = YES;
    } else {
        NSLog(@"failed to add key %@", keyName);
    }
    
    return result;
}

- (SecKeyRef)_getKeyNamed:(NSString *)keyName
{
    OSStatus    err;
    SecKeyRef   keyRef;
    NSData *    keyTagData;
    
    keyRef = NULL;
	
    keyTagData = [keyName dataUsingEncoding:NSUTF8StringEncoding];
    assert(keyTagData != nil);
    
    err = SecItemCopyMatching((CFDictionaryRef)
			[NSDictionary dictionaryWithObjectsAndKeys:
			 (id)
			 kSecClassKey,           kSecClass,
			 keyTagData,             kSecAttrApplicationTag,
			 kCFBooleanTrue,         kSecReturnRef,
			 nil
			],
			(CFTypeRef *) &keyRef
	);
    assert( (err == noErr) == (keyRef != NULL) );
    
    return keyRef;
}

/* Private Crypto functions END */

/* Set selector sets the method that is called by _processWBO to add to storage */
-(void) setSelector:(SEL)selector
{
	select = selector;
}

/* Take a single WBO from self.wbos and attempt decryption.
 * When this is called, the corresponding bulk key should already be in self.bulk */
-(void) _processWBO
{
	if ([wbos length] > 0) {
		NSDictionary *wbo = [wbos lastObject];
		NSDictionary *bulkKey = [bulk objectForKey:[wbo objectForKey:@"encryption"]];
	
		NSData *bulkIV = [[NSData alloc] initWithBase64EncodedString:[bulkKey objectForKey:@"iv"]];
		NSData *symKey = [bulkKey objectForKey:@"key"];
	
		NSData *cipher = [[NSData alloc] initWithBase64EncodedString:[wbo objectForKey:@"ciphertext"]];
	
		NSLog(@"Decrypting ciphertext %@, with key %@ and iv %@", [cipher base64Encoding], [symKey base64Encoding], [bulkIV base64Encoding]);

		NSString *plainText = [[NSString alloc] initWithData:[cipher AESdecryptWithKey:symKey andIV:bulkIV] encoding:NSUTF8StringEncoding];
		plainText = [plainText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		NSLog(@"Got %@!", plainText);
		
		[[serv store] performSelector:select withObject:plainText];
	} else {
		[serv cryptoDone:CRYPTO_DONE_LAST];
	}
	
	//FIXME: ??
	//[plainText release]; [bulkIV release]; [cipher release];
}

/* Add a WBO to self.wbos. If it's bulk-key hasn't been fetched yet, get it */
-(void) decryptWBO:(NSDictionary *)record
{
	NSDictionary *wbo = [[record objectForKey:@"payload"] JSONValue];
	[wbos addObject:wbo];
	
	NSString *url = [wbo objectForKey:@"encryption"];
	if ([bulk objectForKey:url] == nil) {
		curBulk = url;
		[[serv conn] getResource:[NSURL URLWithString:url] withCallback:self andIndex:GOT_BULK_KEY];
	} else {
		[self _processWBO];
	}
}


-(BOOL) decryptRSA:(NSDictionary *)payload
{
	/* Let's try to decrypt the user's private key */
	unsigned char final[32];
	unsigned char tsalt[50];
	NSData *salt = [[NSData alloc] initWithBase64EncodedString:
					[payload valueForKey:@"salt"]];
	
	[salt getBytes:tsalt];
	PKCS5_PBKDF2_HMAC_SHA1(
		[[serv passphrase] cStringUsingEncoding:NSUTF8StringEncoding],
		-1, tsalt, [salt length], 4096, 32, final
	);
	
	[salt release];
	
	NSData *iv = [[NSData alloc] initWithBase64EncodedString:[payload valueForKey:@"iv"]];
	NSData *aesKey = [[NSData alloc] initWithBytes:final length:32];
	NSData *rawKey = [[NSData alloc] initWithBase64EncodedString:[payload valueForKey:@"keyData"]];
	NSData *rsaKey = [rawKey AESdecryptWithKey:aesKey andIV:iv];
	[iv release]; [rawKey release]; [aesKey release];
	
	/* Hmm, some ASN.1 parsing. YUCK */
	char *rsaKeyBytes = (char *)[rsaKey bytes];
	
	/* Step 1. Is offset 22 a OCTET tag? */
	int off = 22;
	if (0x04 != (int)rsaKeyBytes[off++]) {
		NSLog(@"No OCT tag found at offset 22 in RSA key!");
		return NO;
	}
	
	/* Step 2. Get length of raw key */
	int len = (int)rsaKeyBytes[off];
	int det = len & 0x80;
	if (!det) {
		/* 1 byte length */
		off++; len = len & 0x7f;
	} else {
		/* Multibyte length */
		int bytes = len & 0x7f;
		char tmp[3];
		char *value = calloc(bytes + 1, 2);
		for (int i = 1; i <= bytes; i++) {
			sprintf(tmp, "%02x", rsaKeyBytes[off++]);
			memcpy(value + (bytes * 2) - (i * 2), tmp, 2);
		}
		off++; len = (int)strtol(value, NULL, 16);
		free(value);
	}

	/* Step 3. Sanity check */
	if (off + len > [rsaKey length])
		len = [rsaKey length] - off;
	
	/* Step 4. Now extract actual key */
	NSData *privkey = [rsaKey subdataWithRange:NSMakeRange(off, len)];	
	if (privkey) {
		/* Step 5. Add it to the Keychain */
		uint8_t keyHash[CC_SHA1_DIGEST_LENGTH];
		NSData *keyHashData;
		
		(void) CC_SHA1([privkey bytes], [privkey length], keyHash);
		keyHashData = [NSData dataWithBytes:keyHash length:sizeof(keyHash)];
		assert(keyHashData != NULL);
		[self _installKeyData:privkey name:PRIV_KEY_NAME label:keyHashData private:YES];		
		return YES;
	} else {
		NSLog(@"privkey missing!");
		return NO;
	}
}

-(void) successWithString:(NSString *)response andIndex:(int)i
{
	NSData *symKey;
	NSData *usymKey;
	NSString *cipher;
	
	switch (i) {
		case GOT_PRIV_KEY:
			if ([self decryptRSA:[[[response JSONValue] valueForKey:@"payload"] JSONValue]]) {
				[serv cryptoDone:CRYPTO_DONE_INIT];
			} else {
				[serv cryptoDone:CRYPTO_DONE_FAIL];
			}
			break;
		case GOT_BULK_KEY:
			if (curBulk == nil) {
				NSLog(@"Error: GOT_BULK_KEY without set curBulk!");
			} else {
				/* Decrypt and store bulk key */				
				cipher = [[[[[response JSONValue] objectForKey:@"payload"] JSONValue]
						  objectForKey:@"keyring"] objectForKey:
						  [NSString stringWithFormat:@"%@0.5/%@/storage/keys/pubkey",
						  [[serv conn] cluster], [[serv conn] user]]];

				if (cipher != nil) {
					symKey = [[NSData alloc] initWithBase64EncodedString:cipher];
					NSLog(@"Unwrapping symkey");
					usymKey = [self unwrapSymmetricKey:symKey];
					NSLog(@"Got unwrapped symkey of length %d", [usymKey length]);
					
					/* Add symkey to the bulkkeys ring */
					[bulk setObject:[NSDictionary dictionaryWithObjectsAndKeys:
									 [[[[response JSONValue] objectForKey:@"payload"] JSONValue] objectForKey:@"bulkIV"], @"iv",
									 usymKey, @"key",
									 nil
									 ] forKey:curBulk];
					[self _processWBO];
				} else {
					NSLog(@"Error: Could not find bulk key!");
				}
				curBulk = nil;
			}
			break;
		default:
			NSLog(@"Crypto responder: %d should never happen!", i);
			break;
	}
}

-(void) failureWithError:(NSError *)error andIndex:(int)i
{
	[serv cryptoDone:CRYPTO_DONE_FAIL];
}

-(NSData *) unwrapSymmetricKey:(NSData *)symKey
{
	OSStatus err = noErr;
	size_t cipherBufferSize = 0;
	size_t keyBufferSize = 0;
	
	NSData *key = nil;
	uint8_t *keyBuffer = NULL;
	SecKeyRef privateKey = [self _getKeyNamed:PRIV_KEY_NAME];
	
	cipherBufferSize = SecKeyGetBlockSize(privateKey);
	keyBufferSize = [symKey length];
	
	// Allocate some buffer space. I don't trust calloc.
	keyBuffer = malloc( keyBufferSize * sizeof(uint8_t) );
	memset((void *)keyBuffer, 0x0, keyBufferSize);
	
	err = SecKeyDecrypt(
		privateKey,
		kSecPaddingPKCS1,
		(const uint8_t *)[symKey bytes],
		cipherBufferSize,
		keyBuffer,
		&keyBufferSize
	);
	
	if (err != noErr) {
		NSLog(@"Could not unwrap symmetric key!");
	}
	
	key = [NSData dataWithBytes:(const void *)keyBuffer length:(NSUInteger)keyBufferSize];
	if (keyBuffer) free(keyBuffer);
	
	return key;
}

@end

// NSMutableData (AES) Additions adapted from:
// Copyright (c) 2002 Jim Dovey. All rights reserved.
@implementation NSData (AES)

-(NSData *) AESencryptWithKey:(NSData *)key andIV:(NSData *)iv
{	
	NSUInteger dataLength = [self length];
	size_t bufferSize = dataLength + kCCBlockSizeAES128;
	void *buffer = calloc(bufferSize, sizeof(uint8_t));
	
	size_t numBytesEncrypted = 0;
	CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt, kCCAlgorithmAES128, 0,
										  [key bytes], kCCKeySizeAES256,
										  [iv bytes],
										  [self bytes], dataLength,
										  buffer, bufferSize,
										  &numBytesEncrypted);
	if (cryptStatus == kCCSuccess) {
		return [NSData dataWithBytesNoCopy:buffer length:numBytesEncrypted];
	}
	
	free(buffer);
	return nil;
}


-(NSData *) AESdecryptWithKey:(NSData *)key andIV:(NSData *)iv
{	
	NSUInteger dataLength = [self length];
	size_t bufferSize = dataLength + kCCBlockSizeAES128;
	void *buffer = calloc(bufferSize, sizeof(uint8_t));
	
	size_t numBytesDecrypted = 0;
	CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt, kCCAlgorithmAES128, 0,
										  [key bytes], kCCKeySizeAES256,
										  [iv bytes],
										  [self bytes], dataLength,
										  buffer, bufferSize,
										  &numBytesDecrypted);
	
	if (cryptStatus == kCCSuccess) {
		return [NSData dataWithBytesNoCopy:buffer length:numBytesDecrypted];
	}
	
	free(buffer);
	return nil;
}

@end
