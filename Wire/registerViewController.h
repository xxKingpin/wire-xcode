//
//  registerViewController.h
//  Wire
//
//  Created by Jarrod on 12/7/13.
//  Copyright (c) 2013 VINE Entertainment, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface registerViewController : UIViewController

@property (strong, nonatomic) IBOutlet UITextField *uname;
@property (strong, nonatomic) IBOutlet UITextField *upass;
@property (strong, nonatomic) IBOutlet UITextField *cupass;
@property (strong, nonatomic) IBOutlet UITextField *email;
- (IBAction)touchedBackground:(id)sender;
- (IBAction)touchRegister:(id)sender;

@end
