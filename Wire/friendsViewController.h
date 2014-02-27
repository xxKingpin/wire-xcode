//
//  friendsViewController.h
//  Wire
//
//  Created by Lane Shetron on 12/21/13.
//  Copyright (c) 2013 VINE Entertainment, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface friendsViewController : UITableViewController

@property (retain, nonatomic) NSURLConnection *connection;
@property (retain, nonatomic) NSMutableData *response;

@property (strong, nonatomic) NSDictionary *conversations;
@property (strong, nonatomic) NSArray *friends;

@end