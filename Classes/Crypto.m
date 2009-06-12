//
//  Crypto.m
//  Weave
//
//  Created by Anant Narayanan on 10/04/09.
//  Copyright 2009 Anant Narayanan. All rights reserved.
//

#import	<Foundation/Foundation.h>
#import	<CommonCrypto/CommonHMAC.h>
#import	<CommonCrypto/CommonDigest.h>
#import	<CommonCrypto/CommonCryptor.h>
#import <Security/Security.h>
#import "Crypto.h"
#import "Utility.h"

@implementation Crypto

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

-(NSData *) keyFromPassphrase:(NSString *)phrase withSalt:(NSData *)salt {
	unsigned char final[32];
	unsigned char tsalt[50];
	[salt getBytes:tsalt];
	
	PKCS5_PBKDF2_HMAC_SHA1([phrase cStringUsingEncoding:NSASCIIStringEncoding], 10, tsalt, [salt length], 4096, 32, final);
	return [[NSData alloc] initWithBytes:final length:32];
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

-(SecKeyRef) addPrivateKeyALT:(NSData *)data {
	OSStatus err;
	SecKeyRef keyRef = NULL;
	CFDataRef persistRef = nil;
	
	NSString *name = [NSString stringWithString:@"WeaveKey_Private4"];
	NSData *keyTag = [name dataUsingEncoding:NSASCIIStringEncoding];
	
	NSRange range = NSMakeRange(22, [data length] - 22);
	NSData *realKey = [data subdataWithRange:range];
	
	NSLog([NSString stringWithFormat:@"Subkey is: %@", [realKey base64Encoding]]);
	
	err = SecItemAdd((CFDictionaryRef)[NSDictionary dictionaryWithObjectsAndKeys:
									   (id)kSecClassKey, kSecClass,
									   kSecAttrKeyTypeRSA, kSecAttrKeyType,
									   kSecAttrKeyClassPrivate, kSecAttrKeyClass,
									   keyTag, kSecAttrApplicationTag,
									   realKey, kSecValueData,
									   kCFBooleanTrue, kSecReturnPersistentRef, nil
									   ], (CFTypeRef *) &persistRef);
	
	NSLog([NSString stringWithFormat:@"SecItemAdd returned %d", err]);
	assert(err == noErr);
	CFShow(persistRef);
	
	err = SecItemCopyMatching((CFDictionaryRef)[NSDictionary dictionaryWithObjectsAndKeys:
												(id) persistRef, kSecValuePersistentRef,
												kCFBooleanTrue, kSecReturnRef, nil
												], (CFTypeRef *) &keyRef);
	NSLog([NSString stringWithFormat:@"SecItemCopyMatching returned %d", err]);
	assert(err == noErr);
	CFShow(keyRef);
	CFRelease(persistRef);

	return keyRef;
}

-(SecKeyRef) addPublicKeyALT:(NSData *)data {
	static const uint8_t kPublicKeyData[] = {
		
		0x30, 0x47, 0x02, 0x40, 0x78, 0x74, 0xE4, 0xD6, 0xF2, 0x99, 0xDD, 0x4C, 0x3B, 0xFB, 0xE1, 0x15,
		
		0x92, 0x5A, 0x65, 0x40, 0xF3, 0x3F, 0xAB, 0xEF, 0x78, 0x4B, 0xF5, 0xCA, 0x97, 0x69, 0xAF, 0xB5,
		
		0xFF, 0xC1, 0x0C, 0xE0, 0x39, 0x69, 0x68, 0x01, 0x32, 0x3A, 0xF6, 0xB8, 0xCA, 0xC4, 0xC6, 0x7F,
		
		0xA2, 0x4A, 0x21, 0xB2, 0xC1, 0xE7, 0x8C, 0x7B, 0x3B, 0x64, 0x77, 0x0D, 0xF6, 0xE1, 0x93, 0x04,
		
		0xC0, 0xB9, 0x5D, 0x83, 0x02, 0x03, 0x01, 0x00, 0x01
		
	};
	
	NSData *publicKeyData = [NSData dataWithBytes:kPublicKeyData length:sizeof(kPublicKeyData)];
	
	OSStatus err;
	SecKeyRef keyRef = NULL;
	CFDataRef persistRef = nil;
	
	NSString *name = [NSString stringWithString:@"WeaveKey_Public4"];
	NSData *keyTag = [name dataUsingEncoding:NSASCIIStringEncoding];
	
	err = SecItemAdd((CFDictionaryRef)[NSDictionary dictionaryWithObjectsAndKeys:
									   (id)kSecClassKey, kSecClass,
									   kSecAttrKeyTypeRSA, kSecAttrKeyType,
									   kSecAttrKeyClassPublic, kSecAttrKeyClass,
									   keyTag, kSecAttrApplicationTag,
									   publicKeyData, kSecValueData,
									   kCFBooleanTrue, kSecReturnPersistentRef, nil
									   ], (CFTypeRef *) &persistRef);
	
	NSLog([NSString stringWithFormat:@"SecItemAdd returned %d", err]);
	assert(err == noErr);
	CFShow(persistRef);
	
	err = SecItemCopyMatching((CFDictionaryRef)[NSDictionary dictionaryWithObjectsAndKeys:
	(id) persistRef, kSecValuePersistentRef,
	kCFBooleanTrue, kSecReturnRef, nil
	], (CFTypeRef *) &keyRef);
	
	NSLog([NSString stringWithFormat:@"SecItemCopyMatching returned %d", err]);
	assert(err == noErr);
	CFShow(keyRef);
	
	CFRelease(persistRef);
	
	return keyRef;
}

-(SecKeyRef) addPrivateKey:(NSData *)key {
	OSStatus sanity = noErr;
	SecKeyRef keyRef = NULL;
	CFTypeRef persist = NULL;
	
	NSString *name = [NSString stringWithString:@"WeaveKey_Private1"];
	NSData *keyTag = [[NSData alloc] initWithBytes:[name cStringUsingEncoding:NSASCIIStringEncoding] length:[name length]];
	NSMutableDictionary *privateKeyAttr = [[NSMutableDictionary alloc] init];
	
	[privateKeyAttr setObject:(id)kSecClassKey forKey:(id)kSecClass];
	[privateKeyAttr setObject:(id)kSecAttrKeyTypeRSA forKey:(id)kSecAttrKeyType];
	[privateKeyAttr	setObject:(id)keyTag forKey:(id)kSecAttrApplicationTag];
	[privateKeyAttr setObject:(id)key forKey:(id)kSecValueData];
	[privateKeyAttr setObject:[NSNumber numberWithBool:YES] forKey:(id)kSecReturnPersistentRef];
	
	sanity = SecItemAdd((CFDictionaryRef) privateKeyAttr, (CFTypeRef *)&persist);
	
	if (sanity == noErr) {
		NSLog(@"Key added... Checking for persist");
		if (persist) {
			NSLog([NSString stringWithFormat:@"persist found: %@", persist]);
			keyRef = [self getKeyRefWithPersistentKeyRef:persist];
		} else {
			[privateKeyAttr removeObjectForKey:(id)kSecValueData];
			[privateKeyAttr setObject:[NSNumber numberWithBool:YES] forKey:(id)kSecReturnRef];
			sanity = SecItemCopyMatching((CFDictionaryRef) privateKeyAttr, (CFTypeRef *)&keyRef);
			NSLog([NSString stringWithFormat:@"no persist, found keyref: %d / %d", keyRef, sanity]);
		}
	} else if (sanity == errSecDuplicateItem) {
		NSLog(@"Existing key found, retrieving reference");
		keyRef = [self getPrivateKey];
		
		if (!keyRef)
			NSLog(@"Could not retrieve!");
	} else {
		NSLog([NSString stringWithFormat:@"Could not add key to chain! Error code: %d", sanity]);
	}
	
	[keyTag release];
	[privateKeyAttr release];
	if (persist)
		CFRelease(persist);

	return keyRef;
}

-(SecKeyRef) getPrivateKey {
	OSStatus sanityCheck = noErr;
	SecKeyRef privateKeyReference = NULL;
	
	NSString *name = [NSString stringWithString:@"WeaveKey_Private1"];
	NSData *keyTag = [[NSData alloc] initWithBytes:[name cStringUsingEncoding:NSASCIIStringEncoding] length:[name length]];
	
	NSMutableDictionary *queryPrivateKey = [[NSMutableDictionary alloc] init];
		
	// Set the private key query dictionary.
	[queryPrivateKey setObject:(id)kSecClassKey forKey:(id)kSecClass];
	[queryPrivateKey setObject:keyTag forKey:(id)kSecAttrApplicationTag];
	[queryPrivateKey setObject:(id)kSecAttrKeyTypeRSA forKey:(id)kSecAttrKeyType];
	[queryPrivateKey setObject:[NSNumber numberWithBool:YES] forKey:(id)kSecReturnRef];
		
	// Get the key.
	sanityCheck = SecItemCopyMatching((CFDictionaryRef)queryPrivateKey, (CFTypeRef *)&privateKeyReference);
	
	if (sanityCheck != noErr) {
		NSLog([NSString stringWithFormat:@"Could not retrieve private key! Error code: %d", sanityCheck]);
		privateKeyReference = NULL;
	} else {
		NSLog([NSString stringWithFormat:@"Got key: %d with %d", privateKeyReference, sanityCheck]);
	}
		
	[queryPrivateKey release];
	return privateKeyReference;
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
	NSLog([NSString stringWithFormat:@"Got retval %d for lookup", sanityCheck]);
	[queryKey release];
	
	NSLog([NSString stringWithFormat:@"Got keyRef %d for persist %d", keyRef, persistentRef]);
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
