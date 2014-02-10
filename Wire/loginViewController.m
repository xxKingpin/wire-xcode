//
//  loginViewController.m
//  Wire
//
//  Created by Lane Shetron on 12/7/13.
//  Copyright (c) 2013 VINE Entertainment, Inc. All rights reserved.
//

#import "loginViewController.h"

@interface loginViewController ()

@end

@implementation loginViewController

@synthesize uname, upass, bSubmit;

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
    
    self.uname.delegate = self;
    self.upass.delegate = self;
    
    uname.borderStyle = UITextBorderStyleRoundedRect;
    upass.borderStyle = UITextBorderStyleRoundedRect;
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
    return NO;
}

- (IBAction)touchBackground:(id)sender {
    [uname resignFirstResponder];
    [upass resignFirstResponder];
}
/****/

- (IBAction)touchDown:(id)sender {
    //[sender setBackgroundColor:[UIColor colorWithRed:0.812 green:0.404 blue:0.404 alpha:1.0]];
    
    if ([uname.text length] != 0 && [upass.text length] != 0)
    {
        // send login request to graffiti
        NSString *post = [NSString stringWithFormat:@"wire=wire&wire_user=%@&wire_pass=%@", uname.text, upass.text];
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
    NSString *responseStr = [[NSString alloc] initWithData:self.response encoding:NSUTF8StringEncoding];
    NSLog(@"Response: %@", responseStr);
    
    if ([responseStr  isEqual: @"1"])
    {
        NSLog(@"Login successful.");
        //[self.navigationController popViewControllerAnimated:YES];
        [self.view.window.rootViewController dismissViewControllerAnimated:YES completion:nil];
    }
    else
    {
        NSLog(@"Login failed.");
    }
    
    // release connection & response data
    connection = nil;
    self.response = nil;
}

@end
