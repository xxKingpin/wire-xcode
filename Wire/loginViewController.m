//
//  loginViewController.m
//  Wire
//
//  Created by Lane Shetron on 12/7/13.
//  Copyright (c) 2013 VINE Entertainment, Inc. All rights reserved.
//

#import "loginViewController.h"
#import "wireAppDelegate.h"

@interface loginViewController ()

@end

@implementation loginViewController

@synthesize uname, upass, bSubmit, activityIndicator;

int delta;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [self.navigationController setNavigationBarHidden:YES];
    
    self.uname.delegate = self;
    self.upass.delegate = self;
    
    uname.borderStyle = UITextBorderStyleRoundedRect;
    upass.borderStyle = UITextBorderStyleRoundedRect;
    
    self.conversations = [[NSMutableDictionary alloc] init];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    /// automatic login
    // read from plist
    NSArray *sysPaths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,NSUserDomainMask, YES);
    NSString *prefsDirectory = [[sysPaths objectAtIndex:0] stringByAppendingPathComponent:@"/Preferences"];
    NSString *outputFilePath = [prefsDirectory stringByAppendingPathComponent:@"data.plist"];
    NSDictionary *plistData = [NSDictionary dictionaryWithContentsOfFile:outputFilePath];
    if ([[plistData objectForKey:@"username"] length] != 0 && [[plistData objectForKey:@"token"] length] != 0)
    {
        wireAppDelegate *appDelegate = (wireAppDelegate *)[[UIApplication sharedApplication] delegate];
        NSString *post = [NSString stringWithFormat:@"wire=wire&wire_user=%@&wire_token=%@&push_token=%@", [plistData objectForKey:@"username"], [plistData objectForKey:@"token"], appDelegate.apnsToken];
        NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
        NSString *postLength = [NSString stringWithFormat:@"%d", [postData length]];
        NSMutableURLRequest *loginRequest = [[NSMutableURLRequest alloc] init];
        [loginRequest setURL:[NSURL URLWithString:@"http://graffiti.im/index.php"]];
        [loginRequest setHTTPMethod:@"POST"];
        [loginRequest setValue:postLength forHTTPHeaderField:@"Content-Length"];
        [loginRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
        [loginRequest setHTTPBody:postData];
        NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:loginRequest delegate:self];
        self.connection = conn;
        self.response = [[NSMutableData alloc] init];
        [conn start];
        self.activityIndicator.hidden = NO;
        NSLog(@"Automatic login request sent.");
        self.conversations = [plistData objectForKey:@"conversations"];
    }
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/* Hide keyboard on return/background press */
- (BOOL)textFieldShouldReturn: (UITextField *)textField
{
    [textField resignFirstResponder];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:0.3];
        CGRect rect = self.view.window.frame;
        rect.origin.y = 0;
        rect.size.height -= delta;
        self.view.window.frame = rect;
        [UIView commitAnimations];
        delta = 0;
    }
    
    return NO;
}

- (IBAction)touchBackground:(id)sender {
    [uname resignFirstResponder];
    [upass resignFirstResponder];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:0.3];
        CGRect rect = self.view.window.frame;
        rect.origin.y = 0;
        rect.size.height -= delta;
        self.view.window.frame = rect;
        [UIView commitAnimations];
        delta = 0;
    }
}
/****/

- (IBAction)beganEditingPass:(id)sender {
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.3];
    CGRect rect = self.view.window.frame;
    rect.origin.y = -180;
    rect.size.height += 180;
    self.view.window.frame = rect;
    [UIView commitAnimations];
    delta += 180;
}


- (IBAction)touchDown:(id)sender {
    //[sender setBackgroundColor:[UIColor colorWithRed:0.812 green:0.404 blue:0.404 alpha:1.0]];
    [uname resignFirstResponder];
    [upass resignFirstResponder];
    
    if ([uname.text length] != 0 && [upass.text length] != 0)
    {
        // send login request to graffiti
        wireAppDelegate *appDelegate = (wireAppDelegate *)[[UIApplication sharedApplication] delegate];
        NSString *post = [NSString stringWithFormat:@"wire=wire&wire_user=%@&wire_pass=%@&push_token=%@", uname.text, upass.text, appDelegate.apnsToken];
        NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
        NSString *postLength = [NSString stringWithFormat:@"%d", [postData length]];
        NSMutableURLRequest *loginRequest = [[NSMutableURLRequest alloc] init];
        [loginRequest setURL:[NSURL URLWithString:@"http://graffiti.im/index.php"]];
        [loginRequest setHTTPMethod:@"POST"];
        [loginRequest setValue:postLength forHTTPHeaderField:@"Content-Length"];
        [loginRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
        [loginRequest setHTTPBody:postData];
        NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:loginRequest delegate:self];
        self.connection = conn;
        self.response = [[NSMutableData alloc] init]; // this is important apparently!
        [conn start]; // initiate connection
        NSLog(@"login request sent");
        NSLog(@"%@", post);
    }
    else
    {
        UIAlertView *incompleteAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Please complete both fields." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [incompleteAlert show];
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
    //NSString *responseStr = [[NSString alloc] initWithData:self.response encoding:NSUTF8StringEncoding];
    self.activityIndicator.hidden = YES;
    NSError *error;
    NSArray *response = [NSJSONSerialization JSONObjectWithData:self.response options:kNilOptions error:&error];
    NSLog(@"Response: %@", response);
    
    if ([response[0]  isEqual: @"1"])
    {
        NSLog(@"Login successful.");

        // update plist
        NSString *error;
        NSDictionary *plistDict = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:response[2], response[1], self.conversations, nil] forKeys:[NSArray arrayWithObjects:@"username", @"token", @"conversations", nil]];
        NSData *plistData = [NSPropertyListSerialization dataFromPropertyList:plistDict format:NSPropertyListXMLFormat_v1_0 errorDescription:&error];
        
        NSArray *sysPaths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,NSUserDomainMask, YES);
        NSString *prefsDirectory = [[sysPaths objectAtIndex:0] stringByAppendingPathComponent:@"/Preferences"];
        NSString *outputFilePath = [prefsDirectory stringByAppendingPathComponent:@"data.plist"];
        if (plistData)
        {
            [plistData writeToFile:outputFilePath atomically:YES];
        }
        
        [self.view.window.rootViewController dismissViewControllerAnimated:YES completion:nil];
    }
    else if (response == nil)
    {
        // do nothing
    }
    else
    {
        UIAlertView *loginFailAlert = [[UIAlertView alloc] initWithTitle:@"Login Failed" message:@"Your username or password is incorrect." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [loginFailAlert show];
        NSLog(@"Login failed.");
    }
    
    // release connection & response data
    connection = nil;
    self.response = nil;
}

@end
