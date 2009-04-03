/*
 *  WeaveResponder.h
 *  Weave
 *
 *  Created by Anant Narayanan on 03/04/09.
 *  Copyright 2009 Anant Narayanan. All rights reserved.
 *
 */

@protocol WeaveResponder

-(void) successWithString:(NSString *)response andIndex:(int)i;
-(void) failureWithError:(NSError *)error andIndex:(int)i;

@end
