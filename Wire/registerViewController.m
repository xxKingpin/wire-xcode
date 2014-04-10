//
//  registerViewController.m
//  Wire
//
//  Created by Jarrod on 12/7/13.
//  Copyright (c) 2013 VINE Entertainment, Inc. All rights reserved.
//

#import "registerViewController.h"

@interface registerViewController ()

@end

@implementation registerViewController

@synthesize uname, upass, cupass, email;

float delta;

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
	// Do any additional setup after loading the view.
    
    self.uname.delegate = self;
    self.upass.delegate = self;
    self.cupass.delegate = self;
    self.email.delegate = self;
    
    uname.borderStyle = UITextBorderStyleRoundedRect;
    upass.borderStyle = UITextBorderStyleRoundedRect;
    cupass.borderStyle = UITextBorderStyleRoundedRect;
    email.borderStyle = UITextBorderStyleRoundedRect;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/* Hide keyboard on return/background press */
- (BOOL)textFieldShouldReturn: (UITextField *)textField
{
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.3];
    CGRect rect = self.view.window.frame;
    rect.origin.y += delta;
    rect.size.height -= delta;
    self.view.window.frame = rect;
    [UIView commitAnimations];
    delta = 0.0f;
    
    [textField resignFirstResponder];
    return NO;
}

- (IBAction)touchedBackground:(id)sender {
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.3];
    CGRect rect = self.view.window.frame;
    rect.origin.y += delta;
    rect.size.height -= delta;
    self.view.window.frame = rect;
    [UIView commitAnimations];
    delta = 0.0f;
    
    [uname resignFirstResponder];
    [upass resignFirstResponder];
    [cupass resignFirstResponder];
    [email resignFirstResponder];
}

- (IBAction)touchRegister:(id)sender {
    if ([uname.text length] == 0 || [upass.text length] == 0 || [cupass.text length] == 0 || [email.text length] == 0)
    {
        UIAlertView *incompleteAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Please complete all fields." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [incompleteAlert show];
    }
    else if (![upass.text isEqualToString:cupass.text])
    {
        UIAlertView *mismatchAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Your passwords do not match." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [mismatchAlert show];
    }
    else
    {
        // submit registration data to graffiti
        NSString *post = [NSString stringWithFormat:@"wire=wire&wire_user=%@&wire_pass=%@&wire_email=%@&wire_pass_confirm=%@", uname.text, upass.text, email.text, cupass.text];
        NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
        NSString *postLength = [NSString stringWithFormat:@"%d", [postData length]];
        NSMutableURLRequest *registrationRequest = [[NSMutableURLRequest alloc] init];
        [registrationRequest setURL:[NSURL URLWithString:@"http://graffiti.im/index.php"]];
        [registrationRequest setHTTPMethod:@"POST"];
        [registrationRequest setValue:postLength forHTTPHeaderField:@"Content-Length"];
        [registrationRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
        [registrationRequest setHTTPBody:postData];
        NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:registrationRequest delegate:self];
        self.connection = conn;
        self.response = [[NSMutableData alloc] init];
        [conn start];
        NSLog(@"registration request sent");
    }
}

- (IBAction)editingBegan:(UITextField *)sender {
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.3];
    CGRect rect = self.view.window.frame;
    float lastDelta = (sender.frame.origin.y - delta) - ((rect.size.height - delta) / 4);
    delta += lastDelta;
    rect.origin.y -= lastDelta;
    rect.size.height += lastDelta;
    self.view.window.frame = rect;
    [UIView commitAnimations];
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
    //NSString *responseStr = [[NSString alloc] initWithData:self.response encoding:NSUTF8StringEncoding];
    NSArray *response = [NSJSONSerialization JSONObjectWithData:self.response options:kNilOptions error:&error];
    NSLog(@"Response: %@", response);
    
    if ([response[0] isEqual:@"0"])
    {
        UIAlertView *incompleteAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Please complete all fields." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [incompleteAlert show];
    }
    else if ([response[0]  isEqual: @"1"])
    {
        UIAlertView *mismatchAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Your passwords do not match." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [mismatchAlert show];
    }
    else if ([response[0] isEqual:@"2"])
    {
        UIAlertView *invalidAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Please enter a valid email address." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [invalidAlert show];
    }
    else if ([response[0] isEqual:@"3"])
    {
        UIAlertView *accountAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"There is already an account matching that username or email." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [accountAlert show];
    }
    else if ([response[0] isEqual:@"4"])
    {
        UIAlertView *databaseAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Registration failed. Please try again." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [databaseAlert show];
    }
    else if ([response[0] isEqual:@"5"])
    {
        NSLog(@"Registration successful.");
        
        NSString *error;
        NSDictionary *plistDict = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:response[2], response[1], nil] forKeys:[NSArray arrayWithObjects:@"username", @"address", nil]];
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
    else
    {
        UIAlertView *failAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Something went wrong. Sorry about that." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [failAlert show];
    }
    
    // release connection & response data
    connection = nil;
    self.response = nil;
}

@end