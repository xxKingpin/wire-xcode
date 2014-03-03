//
//  friendsViewController.m
//  Wire
//
//  Created by Lane Shetron on 12/21/13.
//  Copyright (c) 2013 VINE Entertainment, Inc. All rights reserved.
//

#import "friendsViewController.h"
#import "wireModelController.h"
#import "wireDataViewController.h"
#import "wireConversations.h"

@interface friendsViewController ()

@end

@implementation friendsViewController


- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;

    // load plist
    NSURL *plist = [[NSBundle mainBundle] URLForResource:@"data" withExtension:@"plist"];
    NSDictionary *plistData = [NSDictionary dictionaryWithContentsOfURL:plist];
    self.conversations = [plistData objectForKey:@"conversations"];
    self.friends = [plistData objectForKey:@"friends"];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self updateConversationsData];
}

- (void)updateConversationsData
{
    // load plist
    NSURL *plist = [[NSBundle mainBundle] URLForResource:@"data" withExtension:@"plist"];
    NSDictionary *plistData = [NSDictionary dictionaryWithContentsOfURL:plist];
    self.conversations = [plistData objectForKey:@"conversations"];
    self.friends = [plistData objectForKey:@"friends"];
    
    // update with data from server
    NSMutableArray *lastMessages = [[NSMutableArray alloc] init];
    for (id user in self.conversations)
    {
        NSDate *lastDate;
        for (int i = 0; i < [[self.conversations objectForKey:user] count]; i++)
        {
            if ([lastDate compare:[[[self.conversations objectForKey:user] objectAtIndex:i] objectForKey:@"date"]] == NSOrderedAscending)
            {
                lastDate = [[[self.conversations objectForKey:user] objectAtIndex:i] objectForKey:@"date"];
            }
            else if ([lastDate compare:[[[self.conversations objectForKey:user] objectAtIndex:i] objectForKey:@"date"]] == NSOrderedDescending)
            {
                // do nothing
            }
            else
            {
                // added for checking the first element in the array
                lastDate = [[[self.conversations objectForKey:user] objectAtIndex:i] objectForKey:@"date"];
            }
        }
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        if (user && [dateFormatter stringFromDate:lastDate])
        {
            NSDictionary *lastMessage = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:user, [dateFormatter stringFromDate:lastDate], nil] forKeys:[NSArray arrayWithObjects:@"username", @"date", nil]];
            [lastMessages addObject:lastMessage];
        }
    }
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:lastMessages options:kNilOptions error:&error];
    NSString *jsonStr = [[NSString alloc] initWithBytes:[jsonData bytes] length:[jsonData length] encoding:NSUTF8StringEncoding];
    
    NSString *post = [NSString stringWithFormat:@"wire_update=update&wire_user=%@&wire_token=%@&wire_json=%@", [plistData objectForKey:@"username"], [plistData objectForKey:@"token"], jsonStr];
    NSLog(@"%@", post);
    NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSString *postLength = [NSString stringWithFormat:@"%d", [postData length]];
    NSMutableURLRequest *updateRequest = [[NSMutableURLRequest alloc] init];
    [updateRequest setURL:[NSURL URLWithString:@"http://graffiti.im/wire.php"]];
    [updateRequest setHTTPMethod:@"POST"];
    [updateRequest setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [updateRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [updateRequest setHTTPBody:postData];
    NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:updateRequest delegate:self];
    self.connection = conn;
    self.response = [[NSMutableData alloc] init];
    [conn start];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.response appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"%@", error);
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSError *error;
    NSDictionary *response = [NSJSONSerialization JSONObjectWithData:self.response options:kNilOptions error:&error];
    if ([[response objectForKey:@"aspects"] count] > 0)
    {
        self.conversations = [[NSMutableDictionary alloc] init];
        NSLog(@"Response: %@", response);

        if ([response objectForKey:@"new_data"])
        {
            for (NSDictionary *message in [response objectForKey:@"new_data"])
            {
                if (![self.conversations objectForKey:[message objectForKey:@"username"]])
                {
                    [self.conversations setObject:[NSMutableArray array] forKey:[message objectForKey:@"username"]];
                }
                [[self.conversations objectForKey:[message objectForKey:@"username"]] addObject:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[message objectForKey:@"date"], [message objectForKey:@"imagedata"], nil] forKeys:[NSArray arrayWithObjects:@"date", @"imagedata", nil]]];
            }
        }
        self.friends = [response objectForKey:@"aspects"];

        // update cell list
        NSMutableArray *cells = [[NSMutableArray alloc] init];
        for (id user in self.conversations)
        {
            NSDictionary *cell = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:user, [[[self.conversations objectForKey:user] lastObject] objectForKey:@"date"], nil] forKeys:[NSArray arrayWithObjects:@"username", @"date", nil]];
            [cells addObject:cell];
        }
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:FALSE];
        [cells sortUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];

        NSMutableArray *remainingFriends = [[NSMutableArray alloc] init];
        for (NSDictionary *friend in self.friends)
        {
            [remainingFriends addObject:[NSDictionary dictionaryWithObject:[friend objectForKey:@"username"] forKey:@"username"]];
        }
        for (NSDictionary *friend in cells)
        {
            for (int i = 0; i < [remainingFriends count]; i++)
            {
                if ([friend objectForKey:@"username"] == [remainingFriends[i] objectForKey:@"username"])
                {
                    [remainingFriends removeObjectAtIndex:i];
                }
            }
        }
        NSSortDescriptor *alphabetize = [[NSSortDescriptor alloc] initWithKey:@"username" ascending:TRUE];
        [remainingFriends sortUsingDescriptors:[NSArray arrayWithObject:alphabetize]];
    
        self.cellList = [cells arrayByAddingObjectsFromArray:remainingFriends];
    }
    else
    {
        NSLog(@"%@", response);
    }
  
    // release connection & response data
    self.connection = nil;
    self.response = nil;

    [self.tableView reloadData];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.cellList count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"conversation";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    cell.textLabel.text = [self.cellList[indexPath.row] objectForKey:@"username"];

    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(UITableViewCell *)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    if ([segue.identifier isEqualToString:@"openConversation"])
    {
        wireConversations *vc = [segue destinationViewController];
        if ([sender isKindOfClass:[UITableViewCell class]])
        {
            NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
            vc.friendUsername = [self.cellList[indexPath.row] objectForKey:@"username"];
            vc.conversations = self.conversations;
            
            NSError *error;
            if (self.conversations && self.friends)
            {
                NSURL *plist = [[NSBundle mainBundle] URLForResource:@"data" withExtension:@"plist"];
                NSDictionary *plistOldData = [NSDictionary dictionaryWithContentsOfURL:plist];
                
                if ([plistOldData objectForKey:@"address"])
                {
                    NSURL *plistURL = [[NSBundle mainBundle] URLForResource:@"data" withExtension:@"plist"];
                    NSDictionary *plistDict = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[plistOldData objectForKey:@"username"], [plistOldData objectForKey:@"token"], [plistOldData objectForKey:@"address"], self.conversations, self.friends, [self.cellList[indexPath.row] objectForKey:@"username"], nil] forKeys:[NSArray arrayWithObjects:@"username", @"token", @"address", @"conversations", @"friends", @"recipient", nil]];
                    NSData *plistData = [NSPropertyListSerialization dataFromPropertyList:plistDict format:NSPropertyListXMLFormat_v1_0 errorDescription:&error];
                    if (plistData)
                    {
                        [plistData writeToURL:plistURL atomically:YES];
                    }
                }
                else
                {
                    // I should actually probably add in a provision here to retrieve the address if it isn't already present
                    NSURL *plistURL = [[NSBundle mainBundle] URLForResource:@"data" withExtension:@"plist"];
                    NSDictionary *plistDict = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[plistOldData objectForKey:@"username"], [plistOldData objectForKey:@"token"], self.conversations, self.friends, [self.cellList[indexPath.row] objectForKey:@"username"], nil] forKeys:[NSArray arrayWithObjects:@"username", @"token", @"conversations", @"friends", @"recipient", nil]];
                    NSData *plistData = [NSPropertyListSerialization dataFromPropertyList:plistDict format:NSPropertyListXMLFormat_v1_0 errorDescription:&error];
                    if (plistData)
                    {
                        [plistData writeToURL:plistURL atomically:YES];
                    }
                }
            }
        }
    }
}

 


@end
