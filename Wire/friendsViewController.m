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

}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.conversations count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    
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

/*
#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

 */


@end
