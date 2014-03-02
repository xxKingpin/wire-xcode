//
//  addFriendController.m
//  Wire
//
//  Created by Lane Shetron on 2/10/14.
//  Copyright (c) 2014 VINE Entertainment, Inc. All rights reserved.
//

#import "addFriendController.h"

@interface addFriendController ()

@end

@implementation addFriendController {
    NSArray *searchResults;
    NSString *requestRecipient;
    NSDictionary *plistData;
}


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
    
    NSURL *plist = [[NSBundle mainBundle] URLForResource:@"data" withExtension:@"plist"];
    plistData = [NSDictionary dictionaryWithContentsOfURL:plist];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(BOOL)searchDisplayController:(UISearchDisplayController *)controller
shouldReloadTableForSearchString:(NSString *)searchString
{
    [self filterContentForSearchText:searchString
        scope:[[self.searchDisplayController.searchBar scopeButtonTitles]
            objectAtIndex:[self.searchDisplayController.searchBar
                selectedScopeButtonIndex]]];

    return YES;
}

- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope
{
    // handles finding and returning search information
    if ([searchText length] > 0)
    {
        NSString *post = [NSString stringWithFormat:@"wire_search=%@&wire_username=%@", searchText, [plistData objectForKey:@"username"]];
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
    if (self.response)
    {
        NSArray *responseArray = [NSJSONSerialization JSONObjectWithData:self.response options:kNilOptions error:&error];

        if (responseArray.firstObject)
        {
            searchResults = responseArray;
            [self.searchDisplayController.searchResultsTableView reloadData];
        }
        else
        {
            searchResults = nil;
            [self.searchDisplayController.searchResultsTableView reloadData];
        }
    }
    else
    {
        [self.searchDisplayController.searchResultsTableView reloadData];
    }

    // release connection & response data
    connection = nil;
    self.response = nil;
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
    // Return the number of rows in the section.
    if (tableView == self.searchDisplayController.searchResultsTableView)
    {
        return [searchResults count];
    }
    else
    {
        return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        //cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    // Configure the cell...
    if (tableView == self.searchDisplayController.searchResultsTableView)
    {
        cell.textLabel.text = searchResults[indexPath.row][0];
        if ([[[searchResults objectAtIndex:indexPath.row] objectAtIndex:1] isEqualToNumber:[NSNumber numberWithInt:2]])
        {
            //friendButton.hidden = YES;
            [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
        }
        else
        {
            cell.detailTextLabel.text = @"Add Friend";
            [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
        }
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (![[[searchResults objectAtIndex:indexPath.row] objectAtIndex:1] isEqualToNumber:[NSNumber numberWithInt:2]])
    {
        UIAlertView *requestAlert = [[UIAlertView alloc] initWithTitle:@"Add Friend" message:[NSString stringWithFormat:@"Are you sure you want to send %@ a friend request?", searchResults[indexPath.row][0]] delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Yes", nil];
        [requestAlert show];
        
        requestRecipient = searchResults[indexPath.row][0];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1)
    {
        NSURL *plist = [[NSBundle mainBundle] URLForResource:@"data" withExtension:@"plist"];
        NSDictionary *plistData = [NSDictionary dictionaryWithContentsOfURL:plist];
        
        // send friend request
        NSString *post = [NSString stringWithFormat:@"wire_request=friend&wire_recipient=%@&wire_sender=%@", requestRecipient, [plistData objectForKey:@"username"]];
        NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
        NSString *postLength = [NSString stringWithFormat:@"%d", [postData length]];
        NSMutableURLRequest *friendRequest = [[NSMutableURLRequest alloc] init];
        [friendRequest setURL:[NSURL URLWithString:@"http://graffiti.im/wire.php"]];
        [friendRequest setHTTPMethod:@"POST"];
        [friendRequest setValue:postLength forHTTPHeaderField:@"Content-Length"];
        [friendRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
        [friendRequest setHTTPBody:postData];
        NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:friendRequest delegate:self];
        self.connection = conn;
        self.response = [[NSMutableData alloc] init];
        [conn start];
        NSLog(@"%@", post);
    }
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
