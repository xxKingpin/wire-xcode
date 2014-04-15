//
//  notificationsController.m
//  Wire
//
//  Created by Lane Shetron on 2/15/14.
//  Copyright (c) 2014 VINE Entertainment, Inc. All rights reserved.
//

#import "notificationsController.h"

@interface notificationsController ()

@end

@implementation notificationsController {
    NSArray *notificationsResult;
    NSDictionary *plistData;
}

@synthesize navBar;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    // fix navigation bar in iOS7
    float currentVersion = 7.0;
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= currentVersion) {
        // iOS 7
        navBar.frame = CGRectMake(navBar.frame.origin.x, navBar.frame.origin.y, navBar.frame.size.width, 64);
    }
    
    UIRefreshControl *refresh = [[UIRefreshControl alloc] init];
    refresh.attributedTitle = [[NSAttributedString alloc] initWithString:@"Drag to refresh"];
    [refresh addTarget:self action:@selector(updateNotifications) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refresh;
    
    [self updateNotifications];
}

- (void)updateNotifications
{
    // load plist
    NSArray *sysPaths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,NSUserDomainMask, YES);
    NSString *prefsDirectory = [[sysPaths objectAtIndex:0] stringByAppendingPathComponent:@"/Preferences"];
    NSString *outputFilePath = [prefsDirectory stringByAppendingPathComponent:@"data.plist"];
    plistData = [NSDictionary dictionaryWithContentsOfFile:outputFilePath];
    
    // load recent notifications
    NSString *post = [NSString stringWithFormat:@"wire_notifications=wire&wire_user=%@", [plistData objectForKey:@"username"]];
    NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSString *postLength = [NSString stringWithFormat:@"%d", [postData length]];
    NSMutableURLRequest *searchRequest = [[NSMutableURLRequest alloc] init];
    [searchRequest setURL:[NSURL URLWithString:@"http://graffiti.im/wire.php"]];
    [searchRequest setHTTPMethod:@"POST"];
    [searchRequest setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [searchRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [searchRequest setHTTPBody:postData];
    NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:searchRequest delegate:self];
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
    [self.refreshControl endRefreshing];

    NSError *error;
    if (self.response)
    {
        NSArray *notifications = [NSJSONSerialization JSONObjectWithData:self.response options:kNilOptions error:&error];
        NSLog(@"%@", notifications);
        if (notifications.firstObject)
        {
            notificationsResult = notifications;
            [self.tableView reloadData];
        }
        /*else
        {
            notificationsResult = nil;
            [self.tableView reloadData];
        }*/
    }
    
    // release connection & response data
    connection = nil;
    self.response = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
#warning Potentially incomplete method implementation.
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [notificationsResult count];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *notification = [notificationsResult objectAtIndex:indexPath.row];
    if ([[notification objectForKey:@"content"] rangeOfString:@"sent you a friend request"].location != NSNotFound)
    {
        return 73.0f;
    }
    else
    {
        return 44.0f;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    
    // Configure the cell...
    NSDictionary *notification = [notificationsResult objectAtIndex:indexPath.row];
    if ([[notification objectForKey:@"content"] rangeOfString:@"sent you a friend request"].location != NSNotFound)
    {
        cell = [tableView dequeueReusableCellWithIdentifier:@"request" forIndexPath:indexPath];
        UILabel *contentLabel = (UILabel *)[cell viewWithTag:3];
        contentLabel.text = [notification objectForKey:@"content"];
    }
    else
    {
        cell = [tableView dequeueReusableCellWithIdentifier:@"normal" forIndexPath:indexPath];
        cell.textLabel.text = [notification objectForKey:@"content"];
    }
    
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

- (IBAction)returnToFriends:(id)sender {
    [self.view.window.rootViewController dismissViewControllerAnimated:YES completion:nil];
}
- (IBAction)requestAccept:(UIButton *)sender {
    UIView *parentView = sender.superview;
    while (![parentView.class isSubclassOfClass:UITableViewCell.class])
    {
        parentView = parentView.superview;
    }
    if ([parentView.class isSubclassOfClass:UITableViewCell.class])
    {
        UITableViewCell *cell = (UITableViewCell *) parentView;
        NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
        
        // tell server request has been accepted
        NSDictionary *notification = [notificationsResult objectAtIndex:indexPath.row];
        NSString *post = [NSString stringWithFormat:@"wire_request=friend&wire_recipient=%@&wire_sender=%@&wire_response=accept",
                [plistData objectForKey:@"username"], [notification objectForKey:@"sender"]]; // we should add in the login token here, otherwise someone could easily friend whoever they want
        NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
        NSString *postLength = [NSString stringWithFormat:@"%d", [postData length]];
        NSMutableURLRequest *searchRequest = [[NSMutableURLRequest alloc] init];
        [searchRequest setURL:[NSURL URLWithString:@"http://graffiti.im/wire.php"]];
        [searchRequest setHTTPMethod:@"POST"];
        [searchRequest setValue:postLength forHTTPHeaderField:@"Content-Length"];
        [searchRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
        [searchRequest setHTTPBody:postData];
        NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:searchRequest delegate:self];
        self.connection = conn;
        self.response = [[NSMutableData alloc] init];
        [conn start];
        
        // alert user
        UIAlertView *acceptAlert = [[UIAlertView alloc] initWithTitle:@"Making Friends" message:@"Friend request accepted!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [acceptAlert show];
        
        // change UI
        [sender setHidden:YES];
        UIButton *declineBtn = (UIButton *)[cell viewWithTag:5];
        [declineBtn setHidden:YES];
        UILabel *detail = (UILabel *)[cell viewWithTag:2];
        [detail setHidden:NO];
        detail.text = @"Accepted!";
        [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
    }
}

- (IBAction)requestDecline:(UIButton *)sender {
    UIView *parentView = sender.superview;
    while (![parentView.class isSubclassOfClass:UITableViewCell.class])
    {
        parentView = parentView.superview;
    }
    if ([parentView.class isSubclassOfClass:UITableViewCell.class])
    {
        UITableViewCell *cell = (UITableViewCell *) parentView;
        NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
        
        // tell server request declined
        NSDictionary *notification = [notificationsResult objectAtIndex:indexPath.row];
        NSString *post = [NSString stringWithFormat:@"wire_request=friend&wire_recipient=%@&wire_sender=%@&wire_response=decline",
                [plistData objectForKey:@"username"], [notification objectForKey:@"sender"]]; // we should add in the login token here, otherwise someone could easily friend whoever they want
        NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
        NSString *postLength = [NSString stringWithFormat:@"%d", [postData length]];
        NSMutableURLRequest *searchRequest = [[NSMutableURLRequest alloc] init];
        [searchRequest setURL:[NSURL URLWithString:@"http://graffiti.im/wire.php"]];
        [searchRequest setHTTPMethod:@"POST"];
        [searchRequest setValue:postLength forHTTPHeaderField:@"Content-Length"];
        [searchRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
        [searchRequest setHTTPBody:postData];
        NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:searchRequest delegate:self];
        self.connection = conn;
        self.response = [[NSMutableData alloc] init];
        [conn start];
    
        // alert user
        UIAlertView *declineAlert = [[UIAlertView alloc] initWithTitle:@"Request Declined" message:@"You have declined this friend request." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [declineAlert show];
        
        // change UI
        [sender setHidden:YES];
        UIButton *acceptBtn = (UIButton *)[cell viewWithTag:4];
        [acceptBtn setHidden:YES];
        UILabel *detail = (UILabel *)[cell viewWithTag:2];
        [detail setHidden:NO];
        detail.text = @"Request Declined";
    }
}
@end
