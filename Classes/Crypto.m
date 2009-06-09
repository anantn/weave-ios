//
//  Crypto.m
//  Weave
//
//  Created by Anant Narayanan on 10/04/09.
//  Copyright 2009 Anant Narayanan. All rights reserved.
//

#import "Crypto.h"
#import "Utility.h"

@implementation Crypto

-(NSData *) keyFromPassphrase:(NSString *)phrase withSalt:(NSData *)salt {
	int iter = 4096;
	int keylen = 32;

	int cplen, j, k;
	unsigned char *p;
	unsigned char key[keylen];
	unsigned char digtmp[CC_SHA1_DIGEST_LENGTH], itmp[4];
	
	CCHmacContext hctx;
	unsigned long i = 1;
	p = key;
	
	while (keylen) {
		if (keylen > CC_SHA1_DIGEST_LENGTH)
			cplen = CC_SHA1_DIGEST_LENGTH;
		else
			cplen = keylen;
		
		itmp[0] = (unsigned char)((i >> 24) & 0xff);
		itmp[1] = (unsigned char)((i >> 16) & 0xff);
		itmp[2] = (unsigned char)((i >> 8) & 0xff);
		itmp[3] = (unsigned char)(i & 0xff);
		
		CCHmacInit(&hctx, kCCHmacAlgSHA1, [phrase cStringUsingEncoding:NSASCIIStringEncoding], [phrase length]);
		CCHmacUpdate(&hctx, [salt bytes], [salt length]);
		CCHmacUpdate(&hctx, itmp, 4);
		CCHmacFinal(&hctx, digtmp);
		
		memcpy(p, digtmp, cplen);
		
		for (j = 1; j < iter; j++) {
			CCHmac(kCCHmacAlgSHA1, phrase, [phrase length], digtmp, CC_SHA1_DIGEST_LENGTH, digtmp);
			for (k = 0; k < cplen; k++)
				p[k] ^= digtmp[k];
		}
		
		i++;
		p += cplen;
		keylen -= cplen;
	}
	
	return [NSData dataWithBytes:p length:32];
}

-(NSData *) unwrapSymmetricKey:(NSData *)symKey withRef:(SecKeyRef)pkey {
	OSStatus sanity = noErr;
	size_t cipherBufferSize = 0;
	size_t keyBufferSize = 0;
	
	NSData *key = nil;
	uint8_t *keyBuffer = NULL;
	
	cipherBufferSize = SecKeyGetBlockSize(pkey);
	keyBufferSize = [symKey length];
	
	keyBuffer = calloc(keyBufferSize, sizeof(uint8_t));
	
	sanity = SecKeyDecrypt(pkey, kSecPaddingPKCS1, (const uint8_t *)[symKey bytes],
						   cipherBufferSize, keyBuffer, &keyBufferSize);
	
	
	if (sanity != noErr) {
		NSLog(@"Could not unwrap symmetric key!");
	}
	
	key = [NSData dataWithBytes:(const void *)keyBuffer length:(NSUInteger)keyBufferSize];
	free(keyBuffer);
	
	return key;
}

-(SecKeyRef) addPrivateKey:(NSData *)key {
	OSStatus sanity = noErr;
	SecKeyRef keyRef = NULL;
	CFTypeRef persist = NULL;
	
	NSString *name = [NSString stringWithString:@"WeavePrivate"];
	NSData *keyTag = [[NSData alloc] initWithBytes:[name cStringUsingEncoding:NSASCIIStringEncoding] length:[name length]];
	NSMutableDictionary *privateKeyAttr = [[NSMutableDictionary alloc] init];
	
	[privateKeyAttr setObject:(id)kSecClassKey forKey:(id)kSecClass];
	[privateKeyAttr setObject:(id)kSecAttrKeyTypeRSA forKey:(id)kSecAttrKeyType];
	[privateKeyAttr	setObject:(id)keyTag forKey:(id)kSecAttrApplicationTag];
	[privateKeyAttr setObject:(id)key forKey:(id)kSecValueData];
	[privateKeyAttr setObject:[NSNumber numberWithBool:YES] forKey:(id)kSecReturnPersistentRef];
	
	sanity = SecItemAdd((CFDictionaryRef) privateKeyAttr, (CFTypeRef *)&persist);
	
	if (sanity != noErr && sanity != errSecDuplicateItem) {
		NSLog(@"Could not add key to chain!");
	}
	
	keyRef = [self getKeyRefWithPersistentKeyRef:persist];
	[keyTag release];
	[privateKeyAttr release];
	CFRelease(persist);
	
	return keyRef;
}

-(SecKeyRef) getKeyRefWithPersistentKeyRef:(CFTypeRef)persistentRef {
	OSStatus sanityCheck = noErr;
	SecKeyRef keyRef = NULL;
	
	NSMutableDictionary * queryKey = [[NSMutableDictionary alloc] init];
	
	// Set the SecKeyRef query dictionary.
	[queryKey setObject:(id)persistentRef forKey:(id)kSecValuePersistentRef];
	[queryKey setObject:[NSNumber numberWithBool:YES] forKey:(id)kSecReturnRef];
	
	// Get the persistent key reference.
	sanityCheck = SecItemCopyMatching((CFDictionaryRef)queryKey, (CFTypeRef *)&keyRef);
	[queryKey release];
	
	return keyRef;
}
	
@end

// NSMutableData (AES) Additions adapted from:
// Copyright (c) 2002 Jim Dovey. All rights reserved.

@implementation NSData (AES)

-(NSData *) AESencryptWithKey:(NSData *)key andIV:(NSData *)iv {	
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


-(NSData *) AESdecryptWithKey:(NSData *)key andIV:(NSData *)iv {	
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
