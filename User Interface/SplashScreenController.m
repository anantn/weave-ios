/***** BEGIN LICENSE BLOCK *****
 Version: MPL 1.1/GPL 2.0/LGPL 2.1
 
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
 
 Alternatively, the contents of this file may be used under the terms of either
 the GNU General Public License Version 2 or later (the "GPL"), or the GNU
 Lesser General Public License Version 2.1 or later (the "LGPL"), in which case
 the provisions of the GPL or the LGPL are applicable instead of those above.
 If you wish to allow use of your version of this file only under the terms of
 either the GPL or the LGPL, and not to allow others to use your version of
 this file under the terms of the MPL, indicate your decision by deleting the
 provisions above and replace them with the notice and other provisions
 required by the GPL or the LGPL. If you do not delete the provisions above, a
 recipient may use your version of this file under the terms of any one of the
 MPL, the GPL or the LGPL.

 ***** END LICENSE BLOCK *****/


#import "SplashScreenController.h"
#import "Animator.h"

@implementation SplashScreenController

@synthesize bigLogo;
@synthesize title1;
@synthesize title2;
@synthesize arrow;
@synthesize tabHelp;
@synthesize bmkHelp;
@synthesize srchHelp;


//scales a rect by a factor from 0 to 1.0 and preserving the center point
CGRect zoomRect(CGRect inRect, CGFloat scale) 
{
  return CGRectInset(inRect, (inRect.size.width - (inRect.size.width * scale))/2, (inRect.size.height - (inRect.size.height * scale))/2);
}


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
  [super viewDidLoad];
    
  //hide everything, and get ready to do the animation sequence
  animationHasBeenPlayed = NO;
  
  //hide search help, but remember where it was
  srchHelpPos = srchHelp.center;
  srchHelpHidden = srchHelpPos;
  srchHelpHidden.y -= 400;
  srchHelp.center = srchHelpHidden; 
  
  //same for tab help
  tabHelpPos = tabHelp.center;
  tabHelpHidden = tabHelpPos;
  tabHelpHidden.y += 400;
  tabHelp.center = tabHelpHidden;
  
  //and bookmark help
  bmkHelpPos = bmkHelp.center;
  bmkHelpHidden = bmkHelpPos;
  bmkHelpHidden.y += 400;
  bmkHelp.center = bmkHelpHidden;
  
  //hide title1
  title1OrigFrame = title1.frame;
  title1.frame = zoomRect(title1OrigFrame, 0.1);  
  title1.alpha = 0;
  
  //hide title2
  title2OrigFrame = title2.frame;
  title2.frame = zoomRect(title2OrigFrame, 0.1);  
  title2.alpha = 0;
  
  //hide arrow
  arrowPos = arrow.center;
  arrowHidden = arrowPos;
  arrowHidden.x += 400;
  arrow.center = arrowHidden;
  
  
  //hide big logo
  bigLogoOrigFrame = bigLogo.frame;
  bigLogo.frame = zoomRect(bigLogoOrigFrame, 0.1);  
  bigLogo.alpha = 0;
  
  //set up the animator
  NSMutableArray* steps = [NSMutableArray array];
  [steps addObject:[NSDictionary dictionaryWithObjectsAndKeys:self, @"actor", @"flyinLogo", @"action", nil]];
  [steps addObject:[NSDictionary dictionaryWithObjectsAndKeys:self, @"actor", @"flyinTitle1", @"action", nil]];
  [steps addObject:[NSDictionary dictionaryWithObjectsAndKeys:self, @"actor", @"flyinTitle2", @"action", nil]];
  [steps addObject:[NSDictionary dictionaryWithObjectsAndKeys:self, @"actor", @"slideInArrow", @"action", nil]];

  [steps addObject:[NSDictionary dictionaryWithObjectsAndKeys:self, @"actor", @"showSrchHelp", @"action", nil]];
  [steps addObject:[NSDictionary dictionaryWithObjectsAndKeys:self, @"actor", @"hideSrchHelp", @"action", nil]];
  [steps addObject:[NSDictionary dictionaryWithObjectsAndKeys:self, @"actor", @"showTabHelp", @"action", nil]];
  [steps addObject:[NSDictionary dictionaryWithObjectsAndKeys:self, @"actor", @"hideTabHelp", @"action", nil]];
  [steps addObject:[NSDictionary dictionaryWithObjectsAndKeys:self, @"actor", @"showBmkHelp", @"action", nil]];
  [steps addObject:[NSDictionary dictionaryWithObjectsAndKeys:self, @"actor", @"hideBmkHelp", @"action", nil]];
  
  
  animationController = [[[Animator alloc] initWithSteps:steps andID:@"help_animation"] autorelease];

}

- (void) flyinLogo
{
  [UIView setAnimationDelay:0.5];
  [UIView setAnimationDuration:0.2];  
  bigLogo.frame = bigLogoOrigFrame;
  bigLogo.alpha = 1.0;
}


- (void) flyinTitle1
{
  [UIView setAnimationDelay:1.0];
  [UIView setAnimationDuration:0.2];
  title1.frame = title1OrigFrame;
  title1.alpha = 1.0;
}

- (void) flyinTitle2
{
  [UIView setAnimationDelay:0.1];
  [UIView setAnimationDuration:0.2];
  title2.frame = title2OrigFrame;
  title2.alpha = 1.0;
}

- (void) slideInArrow
{
  [UIView setAnimationDelay:0.6];
  [UIView setAnimationDuration:0.2];
  arrow.center = arrowPos;
}



- (void) showLogoAndTitle
{
  bigLogo.alpha = 1;
  title1.alpha = 1;
  title2.alpha = 1;
  arrow.alpha = 1;
}

- (void) dimLogoAndTitle
{
  bigLogo.alpha = 0.3;
  title1.alpha = 0.3;
  title2.alpha = 0.3;
  arrow.alpha = 0.3;
}

- (void) showSrchHelp
{
  [UIView setAnimationDuration:0.4];
  [UIView setAnimationDelay:3];
  srchHelp.center = srchHelpPos;
  [self dimLogoAndTitle];
}

- (void) hideSrchHelp
{
  [UIView setAnimationDuration:0.4];
  [UIView setAnimationDelay:3];
  srchHelp.center = srchHelpHidden;
  [self showLogoAndTitle];
}

- (void) showBmkHelp
{
  [UIView setAnimationDuration:0.4];
  [UIView setAnimationDelay:0.25];
  bmkHelp.center = bmkHelpPos;
  [self dimLogoAndTitle];
}

- (void) hideBmkHelp
{
  [UIView setAnimationDuration:0.4];
  [UIView setAnimationDelay:3];
  bmkHelp.center = bmkHelpHidden;
  [self showLogoAndTitle];
}

- (void) showTabHelp
{
  [UIView setAnimationDuration:0.4];
  [UIView setAnimationDelay:0.25];
  tabHelp.center = tabHelpPos;
  [self dimLogoAndTitle];
}

- (void) hideTabHelp
{
  [UIView setAnimationDuration:0.4];
  [UIView setAnimationDelay:3];
  tabHelp.center = tabHelpHidden;
  [self showLogoAndTitle];
}


- (void)viewDidAppear:(BOOL)animated
{
  [self playAnimation];
}

- (void) playAnimation
{  
  if (!animationHasBeenPlayed)
  {
    animationHasBeenPlayed = YES;
    [animationController play];
  }
}


/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}


@end
