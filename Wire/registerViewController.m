//
//  registerViewController.m
//  Wire
//
//  Created by Jarrod on 12/7/13.
//  Copyright (c) 2013 VINE Entertainment, Inc. All rights reserved.
//

#import "registerViewController.h"

@interface registerViewController ()

@end

@implementation registerViewController

@synthesize uname, upass, cupass, email;

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
    
    self.uname.delegate = self;
    self.upass.delegate = self;
    self.cupass.delegate = self;
    self.email.delegate = self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/* Hide keyboard on return/background press */
- (BOOL)textFieldShouldReturn: (UITextField *)textField
{
    [textField resignFirstResponder];
    return NO;
}

- (IBAction)touchedBackground:(id)sender {
    [uname resignFirstResponder];
    [upass resignFirstResponder];
    [cupass resignFirstResponder];
    [email resignFirstResponder];
}

- (IBAction)touchRegister:(id)sender {
    // submit registration data to graffiti
}
@end