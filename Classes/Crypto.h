//
//  Crypto.h
//  Weave
//
//  Created by Anant Narayanan on 10/04/09.
//  Copyright 2009 Anant Narayanan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonHMAC.h>
#import	<CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonCryptor.h>
#import <Security/Security.h>

@interface Crypto : NSObject {

}

-(NSData *) keyFromPassphrase:(NSString *)phrase withSalt:(NSData *)salt;
-(SecKeyRef) addPrivateKey:(NSData *)key;
-(SecKeyRef) getKeyRefWithPersistentKeyRef:(CFTypeRef)persistentRef;

@end

@interface NSData (AES)

-(NSData *) AESencryptWithKey:(NSData *)key andIV:(NSData *)iv;
-(NSData *) AESdecryptWithKey:(NSData *)key andIV:(NSData *)iv;

@end