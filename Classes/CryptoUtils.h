//
//  CryptoUtils.h
//  Weave
//
//  Created by Dan Walkowski on 10/22/09.
//

#import <Foundation/Foundation.h>

#import	<CommonCrypto/CommonHMAC.h>
#import	<CommonCrypto/CommonDigest.h>
#import	<CommonCrypto/CommonCryptor.h>
#import <Security/Security.h>

#import "Utility.h"

#define KEY_SIZE			2048
#define PRIV_KEY_NAME		@"private"


@interface CryptoUtils : NSObject
//returns true if succesful
+ (BOOL) fetchAndInstallPrivateKeyFor:passphrase;

+ (BOOL) decryptPrivateKey:(NSDictionary *)payload withPassphrase:(NSString*)passphrase;
+ (NSData *) unwrapSymmetricKey:(NSData *)symKey withPrivateKey:(SecKeyRef)privateKey;
+ (NSString*) decryptObject:(NSDictionary*)object withKey:(NSDictionary*)bulkKey;
+ (SecKeyRef)_getKeyNamed:(NSString *)keyName;

@end


@interface NSData (AES)
- (NSData *) AESencryptWithKey:(NSData *)key andIV:(NSData *)iv;
- (NSData *) AESdecryptWithKey:(NSData *)key andIV:(NSData *)iv;
@end

int PKCS5_PBKDF2_HMAC_SHA1(const char *pass, int passlen,
                           const unsigned char *salt, int saltlen, int iter,
                           int keylen, unsigned char *out);
