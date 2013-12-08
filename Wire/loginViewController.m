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
    [conn start]; // initiate connection
    NSLog(@"login request sent");
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
    //int responseInt;
    //[self.response getBytes:&responseInt length:sizeof(responseInt)];
    //responseInt = CFSwapInt32BigToHost(responseInt);
    //NSLog(@"%@", responseStr);
    NSLog(@"%@", self.response);
}

@end
