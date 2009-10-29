//
//  CryptoUtils.m
//  Weave
//
//  Created by Dan Walkowski on 10/22/09.
//  Copyright 2009 ClownWare. All rights reserved.
//

#import "CryptoUtils.h"
#import "Store.h"
#import "Fetcher.h"
#import "NSString+SBJSON.h"

@implementation CryptoUtils

+ (BOOL) fetchAndInstallPrivateKeyFor:passphrase
{
  //get the cluster
	NSString *cl = [NSString stringWithFormat:@"https://auth.services.mozilla.com/user/1/%@/node/weave" /*[_networkPaths objectForKey:@"Node Query URL"]*/, 
                  [[Store getStore] getUsername]];  
	NSData* clusterData = [Fetcher getAbsoluteURLSynchronous:cl];
  NSString* cluster = [[NSString alloc] initWithData:clusterData encoding:NSUTF8StringEncoding];
  
  NSData* privKeyData = [Fetcher getURLSynchronous:@"storage/keys/privkey" /*[_networkPaths objectForKey:@"Private Key URL"]*/ fromCluster:cluster];
  NSString* privKeyString = [[NSString alloc] initWithData:privKeyData encoding:NSUTF8StringEncoding];
  NSDictionary *privKeyJSON = [privKeyString JSONValue];

  NSDictionary *payload = [[privKeyJSON valueForKey:@"payload"] JSONValue];
  return [CryptoUtils decryptPrivateKey:payload withPassphrase:passphrase];
}


+ (BOOL)_installKeyData:(NSData *)keyData name:(NSString *)keyName label:(NSData *)keyAppLabel private:(BOOL)isPrivate
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

+ (SecKeyRef)_getKeyNamed:(NSString *)keyName
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


/** Given a payload containing the user's private RSA key,
 * decrypt it and install it on the system. */
+ (BOOL) decryptPrivateKey:(NSDictionary *)payload withPassphrase:(NSString*)passphrase
{
	/* Let's try to decrypt the user's private key */
	unsigned char final[32];
	unsigned char tsalt[50];
	NSData *salt = [[NSData alloc] initWithBase64EncodedString:
                  [payload valueForKey:@"salt"]];
	
	[salt getBytes:tsalt];
	PKCS5_PBKDF2_HMAC_SHA1(
                         [passphrase cStringUsingEncoding:NSUTF8StringEncoding],
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

+ (NSData *) unwrapSymmetricKey:(NSData *)symKey withPrivateKey:(SecKeyRef) privateKey
{
	OSStatus err = noErr;
	size_t cipherBufferSize = 0;
	size_t keyBufferSize = 0;
	
	NSData *key = nil;
	uint8_t *keyBuffer = NULL;
	//SecKeyRef privateKey = [self _getKeyNamed:PRIV_KEY_NAME];
	
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

+ (NSString*)decryptObject:(NSDictionary*)object withKey:(NSDictionary*)bulkKey
{
	NSData *bulkIV = [bulkKey objectForKey:@"iv"];
	NSData *symKey = [bulkKey objectForKey:@"key"];
	NSData *ciphertext = [[NSData alloc] initWithBase64EncodedString:[object objectForKey:@"ciphertext"]];
  //	NSLog(@"Decrypting ciphertext %@, with key %@ and iv %@", [ciphertext base64Encoding], [symKey base64Encoding], [bulkIV base64Encoding]);
  
	// We need to null-terminate this string, since the ciphertext doesn't include a null
	NSString *plainText = [[NSString alloc] initWithData:[ciphertext AESdecryptWithKey:symKey andIV:bulkIV] encoding:NSUTF8StringEncoding];
	// plainText = [plainText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
  
	// NSLog(@"Got %@!", plainText);		
  //	[[serv store] performSelector:select withObject:plainText];
	return plainText;
}

@end


// NSMutableData (AES) Additions adapted from:
// Copyright (c) 2002 Jim Dovey. All rights reserved.
@implementation NSData (AES)

- (NSData *) AESencryptWithKey:(NSData *)key andIV:(NSData *)iv
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


- (NSData *) AESdecryptWithKey:(NSData *)key andIV:(NSData *)iv
{	
	NSUInteger dataLength = [self length];
	size_t bufferSize = dataLength + kCCBlockSizeAES128;
	void *buffer = calloc(bufferSize, sizeof(uint8_t));
	
	size_t numBytesDecrypted = 0;
	CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding /* MRH experiment */,
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

