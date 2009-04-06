//
//  WeaveService.m
//  Weave
//
//  Created by Anant Narayanan on 31/03/09.
//  Copyright 2009 Anant Narayanan. All rights reserved.
//

#import "WeaveService.h"


@implementation WeaveService

@synthesize cb, conn, protocol, server, baseURI;
@synthesize username, password, passphrase;
@synthesize iv, salt, public_key, private_key;

-(WeaveService *) initWithServer:(NSString *)address {
	self = [super init];
	
	if (self) {
		self.server = address;
		self.protocol = @"https://";
	}
	
	return self;
}

-(void) setCluster {
	NSString *cl = [NSString stringWithFormat:@"%@%@/0.3/api/register/chknode/%@", protocol, server, username];
	NSURL *clurl = [NSURL URLWithString:cl];
	
	conn = [WeaveConnection alloc];
	[conn getResource:clurl withCallback:self andIndex:0];
}

-(void) verifyWithUsername:(NSString *)user password:(NSString *)pwd passphrase:(NSString *)ph andCallback:(id <WeaveVerify>)callback{
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
			[conn getResource:[NSURL URLWithString:[NSString stringWithFormat:@"%@/keys/pubkey", baseURI]] withCallback:self andIndex:2];
			break;
		case 2:
			/* We got public key */
			key = [[[response JSONValue] valueForKey:@"payload"] JSONValue];
			public_key = [[NSString alloc] initWithString:[key valueForKey:@"key_data"]];
			
			[conn getResource:[NSURL URLWithString:[key valueForKey:@"private_key"]] withCallback:self andIndex:3];
			break;
		case 3:
			/* We got private key */
			key = [[[response JSONValue] valueForKey:@"payload"] JSONValue];
			iv = [[NSString alloc] initWithString:[key valueForKey:@"iv"]];
			salt = [[NSString alloc] initWithString:[key valueForKey:@"salt"]];
			private_key = [[NSString alloc] initWithString:[key valueForKey:@"key_data"]];
			
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
