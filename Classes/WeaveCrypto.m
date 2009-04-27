//
//  WeaveCrypto.m
//  Weave
//
//  Created by Anant Narayanan on 10/04/09.
//  Copyright 2009 Anant Narayanan. All rights reserved.
//

#import "WeaveCrypto.h"
#import "WeaveUtility.h"

@implementation WeaveCrypto

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
