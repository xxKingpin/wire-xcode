//
//  wireDataViewController.m
//  Wire
//
//  Created by Lane Shetron on 12/6/13.
//  Copyright (c) 2013 VINE Entertainment, Inc. All rights reserved.
//

#import "wireDataViewController.h"

@interface wireDataViewController ()

@end

@implementation wireDataViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.dataLabel.text = [self.dataObject description];
    if ([_dataObject isKindOfClass:[UIImage class]])
    {
        self.imageObject.image = _dataObject;
    }
}


@end
