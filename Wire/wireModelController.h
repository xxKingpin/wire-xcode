//
//  wireModelController.h
//  Wire
//
//  Created by Lane Shetron on 12/6/13.
//  Copyright (c) 2013 VINE Entertainment, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "wireConversations.h"

@class wireDataViewController;

@interface wireModelController : NSObject <UIPageViewControllerDataSource, wireConversationsDelegate>

@property (retain, nonatomic) NSURLConnection *connection;
@property (retain, nonatomic) NSMutableData *response;
@property (strong, nonatomic) NSString *friendUsername;
@property (strong, nonatomic) NSArray *conversations;

- (wireDataViewController *)viewControllerAtIndex:(NSUInteger)index storyboard:(UIStoryboard *)storyboard;
- (NSUInteger)indexOfViewController:(wireDataViewController *)viewController;

@end