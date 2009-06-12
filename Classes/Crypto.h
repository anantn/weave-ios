//
//  Crypto.h
//  Weave
//
//  Created by Anant Narayanan on 10/04/09.
//  Copyright 2009 Anant Narayanan. All rights reserved.
//

@interface Crypto : NSObject {

}

-(NSData *) keyFromPassphrase:(NSString *)phrase withSalt:(NSData *)salt;
-(NSData *) unwrapSymmetricKey:(NSData *)symKey withRef:(SecKeyRef)pkey;
-(SecKeyRef) getPrivateKey;
-(SecKeyRef) addPrivateKey:(NSData *)key;
-(SecKeyRef) addPublicKeyALT:(NSData *)data;
-(SecKeyRef) addPrivateKeyALT:(NSData *)data;
-(SecKeyRef) getKeyRefWithPersistentKeyRef:(CFTypeRef)persistentRef;

@end

@interface NSData (AES)

-(NSData *) AESencryptWithKey:(NSData *)key andIV:(NSData *)iv;
-(NSData *) AESdecryptWithKey:(NSData *)key andIV:(NSData *)iv;

@end