//
//  wireModelController.m
//  Wire
//
//  Created by Lane Shetron on 12/6/13.
//  Copyright (c) 2013 VINE Entertainment, Inc. All rights reserved.
//

#import "wireModelController.h"

#import "wireDataViewController.h"

/*
 A controller object that manages a simple model -- a collection of month names.
 
 The controller serves as the data source for the page view controller; it therefore implements pageViewController:viewControllerBeforeViewController: and pageViewController:viewControllerAfterViewController:.
 It also implements a custom method, viewControllerAtIndex: which is useful in the implementation of the data source methods, and in the initial configuration of the application.
 
 There is no need to actually create view controllers for each page in advance -- indeed doing so incurs unnecessary overhead. Given the data model, these methods create, configure, and return a new view controller on demand.
 */

@interface wireModelController()
@property (readonly, strong, nonatomic) NSArray *pageData;
@end

@implementation wireModelController

- (id)init
{
    self = [super init];
    if (self) {
        // retrieve messages to/from recipient
        NSString *post = [NSString stringWithFormat:@"wire_type=retrieve&wire_user=%@&wire_recipient=%@", @"user", @"recipient"];
        NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding];
        NSString *postLength = [NSString stringWithFormat:@"%d", [postData length]];
        NSMutableURLRequest *retrieveRequest = [[NSMutableURLRequest alloc] init];
        [retrieveRequest setURL:[NSURL URLWithString:@"http://graffiti.im/wire.php"]];
        [retrieveRequest setHTTPMethod:@"POST"];
        [retrieveRequest setValue:postLength forHTTPHeaderField:@"Content-Length"];
        [retrieveRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
        [retrieveRequest setHTTPBody:postData];
        NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:retrieveRequest delegate:self];
        self.connection = conn;
        self.response = [[NSMutableData alloc] init];
        [conn start]; // initiate connection
        NSLog(@"Conversation retrieval began.");
        
        // Create the data model.
        _pageData = [NSArray arrayWithObject:@"foo"];
        /*
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        _pageData = [[dateFormatter monthSymbols] copy];
         */
    }
    return self;
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
    NSArray *responseArray = [NSJSONSerialization JSONObjectWithData:self.response options:kNilOptions error:&error];
    NSLog(@"Array: %@", responseArray);
    
    // Replace the data model with new information from the server
    NSMutableArray *convoImages = [[NSMutableArray alloc] init];
    [convoImages addObject:@"foo"];
    for (NSString *image in responseArray)
    {
        NSData *decodedData = [[NSData alloc] initWithBase64EncodedString:image options:0];
        UIImage *decodedImage = [[UIImage alloc] initWithData:decodedData];
        [convoImages addObject:decodedImage];
    }
    _pageData = convoImages;
    
    // release connection & response data
    self.connection = nil;
    self.response = nil;
}

/********/

- (wireDataViewController *)viewControllerAtIndex:(NSUInteger)index storyboard:(UIStoryboard *)storyboard
{   
    // Return the data view controller for the given index.
    if (([self.pageData count] == 0) || (index >= [self.pageData count])) {
        return nil;
    }
    
    // Create a new view controller and pass suitable data.
    wireDataViewController *dataViewController = [storyboard instantiateViewControllerWithIdentifier:@"wireDataViewController"];
    dataViewController.dataObject = self.pageData[index];
    return dataViewController;
}

- (NSUInteger)indexOfViewController:(wireDataViewController *)viewController
{   
     // Return the index of the given data view controller.
     // For simplicity, this implementation uses a static array of model objects and the view controller stores the model object; you can therefore use the model object to identify the index.
    return [self.pageData indexOfObject:viewController.dataObject];
}

#pragma mark - Page View Controller Data Source

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    NSUInteger index = [self indexOfViewController:(wireDataViewController *)viewController];
    if ((index == 0) || (index == NSNotFound)) {
        return nil;
    }
    
    index--;
    return [self viewControllerAtIndex:index storyboard:viewController.storyboard];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    NSUInteger index = [self indexOfViewController:(wireDataViewController *)viewController];
    if (index == NSNotFound) {
        return nil;
    }
    
    index++;
    if (index == [self.pageData count]) {
        return nil;
    }
    return [self viewControllerAtIndex:index storyboard:viewController.storyboard];
}

@end
