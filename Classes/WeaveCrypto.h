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

-(NSString *) keyFromPassphrase:(NSString *)phrase withSalt:(NSString *)salt;

@end
