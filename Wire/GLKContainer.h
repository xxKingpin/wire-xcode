//
//  GLKContainer.h
//  Wire
//
//  Created by Lane Shetron on 2/28/14.
//  Copyright (c) 2014 VINE Entertainment, Inc. All rights reserved.
//

#import <GLKit/GLKit.h>
#import "wireDrawing.h"

@interface GLKContainer : GLKViewController

@property (strong, nonatomic) NSString *recipient;
@property (strong, nonatomic) IBOutlet wireDrawing *drawingView;
- (IBAction)eraseDrawing:(id)sender;

@end
