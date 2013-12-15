//
//  wireModelController.h
//  Wire
//
//  Created by Lane Shetron on 12/6/13.
//  Copyright (c) 2013 VINE Entertainment, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class wireDataViewController;

@interface wireModelController : NSObject <UIPageViewControllerDataSource>

- (wireDataViewController *)viewControllerAtIndex:(NSUInteger)index storyboard:(UIStoryboard *)storyboard;
- (NSUInteger)indexOfViewController:(wireDataViewController *)viewController;

@end
