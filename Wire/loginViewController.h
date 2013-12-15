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

@property (strong, nonatomic) IBOutlet UITextField *uname;
@property (strong, nonatomic) IBOutlet UITextField *upass;
@property (strong, nonatomic) IBOutlet UIButton *bSubmit;
- (IBAction)touchDown:(id)sender;
- (IBAction)touchBackground:(id)sender;

@end
