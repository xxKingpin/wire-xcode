//
//  wireDrawing.h
//  Wire
//
//  Created by Lane Shetron on 1/16/14.
//  Copyright (c) 2014 VINE Entertainment, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>

@interface wireDrawing : GLKView

@property (retain, nonatomic) NSURLConnection *connection;
@property (retain, nonatomic) NSMutableData *response;

@property (assign, nonatomic) BOOL hasSignature;
@property (strong, nonatomic) UIImage *signatureImage;
- (IBAction)sendWire:(id)sender;

- (void)erase;

@end
