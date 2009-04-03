//
//  WeaveConnection.m
//  Weave
//
//  Created by Anant Narayanan on 03/04/09.
//  Copyright 2009 Anant Narayanan. All rights reserved.
//

#import "WeaveConnection.h"
#import "WeaveResponder.h"

@implementation WeaveConnection

@synthesize cb, responseData;

-(void) getResource:(NSURL *)url withCallback:(id <WeaveResponder>)callback {
	cb = callback;
	responseData = [[NSMutableData data] retain];
	
	NSURLRequest *request = [NSURLRequest requestWithURL:url];
	[[NSURLConnection alloc] initWithRequest:request delegate:self];
}

-(void) connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	[responseData setLength:0];
}

-(void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	[responseData appendData:data];
}

-(void) connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	[responseData release];
	[cb failureWithError:error];
}

-(void) connectionDidFinishLoading:(NSURLConnection *)connection {
	NSString *responseString = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
	[responseData release];
	
	[cb successWithString:responseString];
}

@end
