//
//  wireRootNavigationController.m
//  Wire
//
//  Created by Lane Shetron on 12/21/13.
//  Copyright (c) 2013 VINE Entertainment, Inc. All rights reserved.
//

#import "wireRootNavigationController.h"

@interface wireRootNavigationController ()

@end

@implementation wireRootNavigationController


bool loginHasStarted = false;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // create login view controller
    UIStoryboard *storyboard = self.storyboard;
    
    if (!loginHasStarted) // avoids restarting login view after signin
    {
        UINavigationController *loginNav = [storyboard instantiateViewControllerWithIdentifier:@"loginNav"];
        [self presentViewController:loginNav animated:YES completion:^{
            loginHasStarted = true;
        }];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
