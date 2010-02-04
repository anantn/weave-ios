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
 Dan Walkowski <dan.walkowski@mozilla.com>
 
 ***** END LICENSE BLOCK *****/

#import "Animator.h"


@implementation Animator

- (id) initWithSteps:(NSArray*)steps andID:(NSString*)id
{
  if ((self = [super init])) 
  {
    animationID = [id retain];
    animationSteps = [steps retain];
    cancelled = NO;
    currentStep = 0;
  }
  return self;
}

- (void)stepComplete:(NSString *)animID success:(NSNumber*)success context:(void *)context
{
  if (success && !cancelled && currentStep < [animationSteps count])
  {
    NSDictionary* nextStep = [animationSteps objectAtIndex:currentStep];
    //check before we do anything
    id actor = [nextStep objectForKey:@"actor"];
    NSString* action = [nextStep objectForKey:@"action"];
    if (actor != nil && action !=nil)
    {
      [UIView beginAnimations:animID context:nil];
      [UIView setAnimationDelegate:self];
      [UIView setAnimationDidStopSelector:@selector(stepComplete:success:context:)];
      [actor performSelector:NSSelectorFromString(action)];
      [UIView commitAnimations];
    }
    currentStep++;
  }
}

- (void) play
{
  //start the ball rolling
  NSNumber* win = [NSNumber numberWithInt:YES];
  
  [self stepComplete:animationID success:win context:nil];
}

- (void)dealloc {
  [super dealloc];
  [animationID release];
  [animationSteps release];
}


@end
