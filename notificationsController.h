//
//  notificationsController.h
//  Wire
//
//  Created by Lane Shetron on 2/15/14.
//  Copyright (c) 2014 VINE Entertainment, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface notificationsController : UITableViewController

- (IBAction)returnToFriends:(id)sender;
@property (strong, nonatomic) IBOutlet UINavigationBar *navBar;
- (IBAction)requestAccept:(id)sender;
- (IBAction)requestDecline:(id)sender;

@property (retain, nonatomic) NSURLConnection *connection;
@property (retain, nonatomic) NSMutableData *response;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@end
