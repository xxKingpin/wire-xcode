//
//  GLKContainer.m
//  Wire
//
//  Created by Lane Shetron on 2/28/14.
//  Copyright (c) 2014 VINE Entertainment, Inc. All rights reserved.
//

#import "GLKContainer.h"

@interface GLKContainer ()

@end

@implementation GLKContainer

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    self.drawingView.recipient = self.recipient;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
