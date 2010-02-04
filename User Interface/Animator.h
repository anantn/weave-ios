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

#import <Foundation/Foundation.h>


//plays a sequence of CA animations one after the other, checking for successful completion or cancelling
// between the steps.  Takes an array of steps, each of which is a dictionary of properties, with at least
// 'actor', which is the object that will perform the animation, and 'action', which is the method to call on actor.

@interface Animator : NSObject 
{
  NSString* animationID;
  NSArray* animationSteps;
  unsigned int currentStep;
  BOOL cancelled;
}

//each step has an actor (id) and an action (nsstring)
- (id) initWithSteps:(NSArray*)steps andID:(NSString*)id;
- (void) play;

@end
