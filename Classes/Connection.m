/***** BEGIN LICENSE BLOCK *****
 Version: MPL 1.1
 
 The contents of this file are subject to the Mozilla Public License Version 
 1.1 (the "License"); you may not use this file except in compliance with 
 the License. You may obtain a copy of the License at 
 http://www.mozilla.org/MPL/
 
 Software distributed under the License is distributed on an "AS IS" basis,
 WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 for the specific language governing rights and limitations under the
 License.
 
 The Original Code is weave-iphone.
 
 The Initial Developer of the Original Code is Mozilla Labs.
 Portions created by the Initial Developer are Copyright (C) 2009
 the Initial Developer. All Rights Reserved.
 
 Contributor(s):
	Anant Narayanan <anant@kix.in>
 
 ***** END LICENSE BLOCK *****/

#import "Connection.h"
#import "Service.h"
#import "JSON.h"

@implementation Connection

@synthesize cb, success, responseData, user, pass, phrase;

-(void) setUser:(NSString *)u password:(NSString *)p andPassphrase:(NSString *)ph {
	user = u;
	pass = p;
	phrase = ph;
}

/* Asynchronous communication */
-(void) getResource:(NSURL *)url withCallback:(id <Responder>)callback andIndex:(int)i {
	index = i;
	cb = callback;
	
	responseData = [[NSMutableData alloc] init];
	NSLog([NSString stringWithFormat:@"Request for %@!", [url path]]);
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
										cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
												timeoutInterval:10];
	
	/* For streaming, we request whoisi style output from server */
	if (pg)
		[request addValue:@"application/whoisi" forHTTPHeaderField:@"Accept"];
	
	[request addValue:user forHTTPHeaderField:@"X-Weave-Username"];
	[request addValue:pass forHTTPHeaderField:@"X-Weave-Password"];
	[request addValue:phrase forHTTPHeaderField:@"X-Weave-Passphrase"];
	[[NSURLConnection alloc] initWithRequest:request delegate:self];
}

-(void) getResource:(NSURL *)url withCallback:(id <Responder>)callback pgIndex:(int)j andIndex:(int)i {
	pg = j;
	currentLength = 0;
	[self getResource:url withCallback:callback andIndex:i];
}

/* Asynchronous POST */
-(void) postTo:(NSURL *)url withData:(NSString *)post callback:(id <Responder>)callback andIndex:(int)i {
	index = i;
	cb = callback;
	NSLog([NSString stringWithFormat:@"Request for %@!", [url path]]);
	
	responseData = [[NSMutableData alloc] init];
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
										cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
													   timeoutInterval:60];

	[request setHTTPMethod:@"POST"];
	[request setHTTPBody:[post dataUsingEncoding:NSASCIIStringEncoding]];
	
	[[NSURLConnection alloc] initWithRequest:request delegate:self];
}

-(void) connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	int code = [(NSHTTPURLResponse *)response statusCode];
	NSLog([NSString stringWithFormat:@"Got response code %d", code]);
	
	if (code != 200) {
		success = NO;
	} else {
		success = YES;
	}
	
	if (pg)
		[cb setTotal:[[(NSHTTPURLResponse *)response allHeaderFields] 
					  objectForKey:@"X-Weave-Records"]];
	
	[responseData setLength:0];
}

-(void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	[responseData appendData:data];
	if (pg) {
		if (!currentLength) {
			[responseData getBytes:&currentLength length:sizeof(unsigned long)];
			currentLength = NSSwapBigLongToHost(currentLength);
		}
		int from = sizeof(unsigned long) + currentLength;
		if ([responseData length] >= from) {
			[cb successWithString:[[[NSString alloc]
									initWithData:[responseData subdataWithRange:
												  NSMakeRange(sizeof(unsigned long), currentLength)]
									encoding:NSUTF8StringEncoding] autorelease] andIndex:pg];
			NSData *new = [responseData subdataWithRange:
						   NSMakeRange(from, [responseData length] - from)];
			[responseData release];
			responseData = [[NSMutableData alloc] initWithData:new];
			currentLength = 0;
		}
	}
}

-(void) connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	[responseData release];
	[cb failureWithError:error andIndex:index];
}

-(void) connectionDidFinishLoading:(NSURLConnection *)connection {
	NSString *responseString;
	
	if (pg)
		responseString = @"";
	else
		responseString = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
	[responseData release];
	
	if (success) {
		[cb successWithString:responseString andIndex:index];
	} else {
		NSLog([NSString stringWithFormat:@"Failed with response: %@", responseString]);
		[cb failureWithError:[NSError errorWithDomain:NSURLErrorDomain code:-1 userInfo:nil] andIndex:index];
	}
}

@end
