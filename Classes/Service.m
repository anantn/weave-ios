//
//  Service.m
//  Weave
//
//  Created by Anant Narayanan on 31/03/09.
//  Copyright 2009 Anant Narayanan. All rights reserved.
//

#import "Service.h"
#import "Utility.h"
#import "Crypto.h"

@implementation Service

@synthesize username, password, passphrase;
@synthesize cb, iv, salt, public_key, private_key;
@synthesize store, conn, crypto, protocol, server, baseURI;

-(Service *) initWithServer:(NSString *)address {
	self = [super init];
	
	if (self) {
		self.server = address;
		self.protocol = @"https://";
		self.store = [[Store alloc] initWithDB:@"/store.sq3"];
		self.crypto = [Crypto alloc];
		self.conn = [Connection alloc];
	}
	
	return self;
}

-(BOOL) loadFromStore {
	return [store loadUserToService:self];
}

-(void) loadFromUser:(NSString *)user password:(NSString *)pwd passphrase:(NSString *)ph andCallback:(id)callback {
	cb = callback;
	password = pwd;
	username = user;
	passphrase = ph;
	
	/* Get & set cluster */
	NSString *cl = [NSString stringWithFormat:@"%@%@/0.3/api/register/chknode/%@", protocol, server, username];
	NSURL *clurl = [NSURL URLWithString:cl];
	[conn getResource:clurl withCallback:self andIndex:0];
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
			public_key = [[NSData alloc] initWithBase64EncodedString:[key valueForKey:@"keyData"]];
			
			[conn getResource:[NSURL URLWithString:[key valueForKey:@"privateKeyUri"]]
				 withCallback:self andIndex:3];
			break;
		case 3:
			/* We got private key */
			key = [[[response JSONValue] valueForKey:@"payload"] JSONValue];
			iv = [[NSData alloc] initWithBase64EncodedString:[key valueForKey:@"iv"]];
			salt = [[NSData alloc] initWithBase64EncodedString:[key valueForKey:@"salt"]];
			private_key = [[NSData alloc] initWithBase64EncodedString:[key valueForKey:@"keyData"]];
			
			[conn getResource:[NSURL URLWithString:[NSString stringWithFormat:@"%@/crypto/bookmarks", baseURI]]
				 withCallback:self andIndex:4];
			break;
		case 4:
			/* Got bookmarks key */
			key = [[[response JSONValue] valueForKey:@"payload"] JSONValue];
			NSData *bmkKey = [[NSData alloc] initWithBase64EncodedString:
							  [key valueForKey:[NSString stringWithFormat:@"%@/keys/pubkey", baseURI]]];
			
			NSData *aesKey = [crypto keyFromPassphrase:passphrase withSalt:salt];
			NSLog([NSString stringWithFormat:@"AES Key length: %d", [aesKey length]]);
			NSData *rsaKey = [private_key AESdecryptWithKey:aesKey andIV:iv];
			NSLog([NSString stringWithFormat:@"RSA Key length: %d", [rsaKey length]]);
			
			if (rsaKey == nil) {
				NSLog(@"AES decryption failed, could not get RSA key!");
				[cb verified:NO];
				break;
			}
			/*
			SecKeyRef pkey = [crypto addPrivateKey:private_key];
			NSData *finalPkey = [crypto unwrapSymmetricKey:bmkKey withRef:pkey];
			
			NSLog([NSString stringWithFormat:@"Unwrapped symmetric key: %@", [finalPkey base64Encoding]]);
			*/
			
			/* We're done! */
			if ([store addUserWithService:self])
				[cb verified:YES];
			else
				[cb verified:NO];
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
	[store release];
    [super dealloc];
}

@end
