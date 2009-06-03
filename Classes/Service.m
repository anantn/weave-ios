//
//  Service.m
//  Weave
//
//  Created by Anant Narayanan on 31/03/09.
//  Copyright 2009 Anant Narayanan. All rights reserved.
//

#import "Service.h"
#import "Utility.h"

@implementation Service

@synthesize cb, conn, crypto, protocol, server, baseURI;
@synthesize username, password, passphrase;
@synthesize iv, salt, public_key, private_key;

-(Service *) initWithServer:(NSString *)address {
	self = [super init];
	
	if (self) {
		self.server = address;
		self.protocol = @"https://";
		//self.crypto = [Crypto alloc];
		self.conn = [Connection alloc];
	}
	
	return self;
}

-(void) setCluster {
	NSString *cl = [NSString stringWithFormat:@"%@%@/0.3/api/register/chknode/%@", protocol, server, username];
	NSURL *clurl = [NSURL URLWithString:cl];
	
	[conn getResource:clurl withCallback:self andIndex:0];
}

-(void) verifyWithUsername:(NSString *)user password:(NSString *)pwd passphrase:(NSString *)ph andCallback:(id <Verifier>)callback{
	cb = callback;
	password = pwd;
	username = user;
	passphrase = ph;
	
	[self setCluster];
}

-(void) successWithString:(NSString *)response andIndex:(int)i{
	NSDictionary *key;
	
	switch (i) {
		case 0:
			/* We got cluster, now actually check username/password */
			baseURI = [NSString stringWithFormat:@"%@%@:%@@%@/0.3/user/%@", protocol, username, password, response, username];
			
			[conn getResource:[NSURL URLWithString:baseURI] withCallback:self andIndex:1];
			break;
		case 1:
			/* We checked username/password, now get public key */
			[conn getResource:[NSURL URLWithString:[NSString stringWithFormat:@"%@/keys/pubkey", baseURI]] 
				 withCallback:self andIndex:2];
			break;
		case 2:
			/* We got public key */
			key = [[[response JSONValue] valueForKey:@"payload"] JSONValue];
			public_key = [NSData dataWithBase64EncodedString:[key valueForKey:@"keyData"]];
			
			[conn getResource:[NSURL URLWithString:[key valueForKey:@"privateKeyUri"]]
				 withCallback:self andIndex:3];
			break;
		case 3:
			/* We got private key */
			key = [[[response JSONValue] valueForKey:@"payload"] JSONValue];
			iv = [NSData dataWithBase64EncodedString:[key valueForKey:@"iv"]];
			salt = [NSData dataWithBase64EncodedString:[key valueForKey:@"salt"]];
			private_key = [NSData dataWithBase64EncodedString:[key valueForKey:@"keyData"]];
			
			[conn getResource:[NSURL URLWithString:[NSString stringWithFormat:@"%@/crypto/bookmarks", baseURI]]
				 withCallback:self andIndex:4];
		case 4:
			/* Got bookmarks key */
			key = [[[response JSONValue] valueForKey:@"payload"] JSONValue];
			NSData *bmkKey = [NSData dataWithBase64EncodedString:
							  [key valueForKey:[NSString stringWithFormat:@"%@/keys/pubkey", baseURI]]];
			
			/*
			NSData *aesKey = [crypto keyFromPassphrase:passphrase withSalt:salt];
			NSData *rsaKey = [private_key AESdecryptWithKey:aesKey andIV:iv];
			
			if (rsaKey == nil) {
				NSLog(@"AES decryption failed, could not get RSA key!");
				[cb verified:NO];
				break;
			}
			
			SecKeyRef pkey = [crypto addPrivateKey:private_key];
			NSData *finalPkey = [crypto unwrapSymmetricKey:bmkKey withRef:pkey];
			
			NSLog([NSString stringWithFormat:@"Unwrapped symmetric key: %@", [finalPkey base64Encoding]]);
			*/
			[cb verified:YES];
			break;
		default:
			NSLog(@"This should never happen!");
			break;
	}
}

-(void) failureWithError:(NSError *)error andIndex:(int)i{
	[cb verified:NO];
}

-(void) dealloc {
	[conn release];
    [super dealloc];
}

@end
