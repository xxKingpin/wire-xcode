//
//  wireDrawing.h
//  Wire
//
//  Created by Lane Shetron on 1/16/14.
//  Copyright (c) 2014 VINE Entertainment, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#import <OpenGLES/ES2/glext.h> // fix for xcode6

@interface wireDrawing : GLKView

@property (retain, nonatomic) NSURLConnection *connection;
@property (retain, nonatomic) NSMutableData *response;
@property (retain, nonatomic) NSString *recipient;

@property (assign, nonatomic) BOOL hasSignature;
@property (strong, nonatomic) UIImage *signatureImage;
- (IBAction)sendWire:(id)sender;

- (IBAction)blackSelected:(id)sender;
- (IBAction)redSelected:(id)sender;
- (IBAction)tealSelected:(id)sender;
- (IBAction)orangeSelected:(id)sender;
- (IBAction)greenSelected:(id)sender;
- (IBAction)pinkSelected:(id)sender;

@property (weak, nonatomic) IBOutlet UIButton *blackButton;
@property (weak, nonatomic) IBOutlet UIButton *redButton;
@property (weak, nonatomic) IBOutlet UIButton *tealButton;
@property (weak, nonatomic) IBOutlet UIButton *orangeButton;
@property (weak, nonatomic) IBOutlet UIButton *greenButton;
@property (weak, nonatomic) IBOutlet UIButton *pinkButton;

- (void)erase;

@end
