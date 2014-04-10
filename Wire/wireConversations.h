//
//  wireConversations.h
//  Wire
//
//  Created by Lane Shetron on 2/10/14.
//  Copyright (c) 2014 VINE Entertainment, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol wireConversationsDelegate;

@interface wireConversations : UIViewController <UIPageViewControllerDelegate>
{
    id<wireConversationsDelegate> delegate;
    
    NSArray *imageData;
}

@property (strong, nonatomic) id<wireConversationsDelegate> delegate;
@property (strong, nonatomic) NSArray *imageData;
@property (strong, nonatomic) NSString *friendUsername;
@property (strong, nonatomic) NSMutableDictionary *conversations;
- (IBAction)unwindToConversation:(UIStoryboardSegue *)segue;

@end

@protocol wireConversationsDelegate

- (void)passImageData:(wireConversations *)WireConversations;

@end
