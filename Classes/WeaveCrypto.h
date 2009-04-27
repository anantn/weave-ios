//
//  WeaveCrypto.h
//  Weave
//
//  Created by Anant Narayanan on 10/04/09.
//  Copyright 2009 Anant Narayanan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonHMAC.h>
#import	<CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonCryptor.h>

@interface WeaveCrypto : NSObject {

}

-(NSData *) keyFromPassphrase:(NSString *)phrase withSalt:(NSData *)salt;

@end

@interface NSData (AES)

-(NSData *) AESencryptWithKey:(NSData *)key andIV:(NSData *)iv;
-(NSData *) AESdecryptWithKey:(NSData *)key andIV:(NSData *)iv;

@end