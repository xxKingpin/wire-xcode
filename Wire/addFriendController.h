//
//  addFriendController.h
//  Wire
//
//  Created by Lane Shetron on 2/10/14.
//  Copyright (c) 2014 VINE Entertainment, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface addFriendController : UITableViewController <UISearchDisplayDelegate, UISearchBarDelegate>

@property (retain, nonatomic) NSURLConnection *connection;
@property (retain, nonatomic) NSMutableData *response;

@end
