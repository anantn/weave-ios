//
//  SearchResultsController.h
//  Weave
//
//  Created by Dan Walkowski on 11/19/09.
//  Copyright 2009 ClownWare. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface SearchResultsController : UIViewController <UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate>
{
  UITableView* resultsTable;
  UIImageView* fancyGraphic;
  NSArray* searchHits;
}

@property (nonatomic, retain) IBOutlet UITableView *resultsTable;
@property (nonatomic, retain) IBOutlet UIImageView *fancyGraphic;

@end
