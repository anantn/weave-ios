//
//  WeaveCrypto.m
//  Weave
//
//  Created by Anant Narayanan on 10/04/09.
//  Copyright 2009 Anant Narayanan. All rights reserved.
//

#import "WeaveCrypto.h"


@implementation WeaveCrypto

-(NSString *) keyFromPassphrase:(NSString *)phrase withSalt:(NSString *)salt {
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
		CCHmacUpdate(&hctx, [salt cStringUsingEncoding:NSASCIIStringEncoding], [salt length]);
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
		keylen-= cplen;
	}
	
	return [NSString stringWithCString:(const char *)key encoding:NSASCIIStringEncoding];
}

@end
