//
//  loginViewController.h
//  Wire
//
//  Created by Lane Shetron on 12/7/13.
//  Copyright (c) 2013 VINE Entertainment, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface loginViewController : UIViewController

@property (retain, nonatomic) NSURLConnection *connection;
@property (retain, nonatomic) NSMutableData *response;

@property (strong, nonatomic) NSMutableDictionary *conversations;
@property (weak, nonatomic) IBOutlet UITextField *uname;
@property (weak, nonatomic) IBOutlet UITextField *upass;
@property (weak, nonatomic) IBOutlet UIButton *bSubmit;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
- (IBAction)touchDown:(id)sender;
- (IBAction)touchBackground:(id)sender;
- (IBAction)beganEditingPass:(id)sender;

@end
