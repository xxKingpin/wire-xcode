//
//  UIColor+colorWithRGB.m
//  Wire
//
//  Created by Lane Shetron on 6/20/14.
//  Copyright (c) 2014 VINE Entertainment, Inc. All rights reserved.
//

#import "UIColor+colorWithRGB.h"

@implementation UIColor (colorWithRGB)

+ (UIColor *)colorWithRGB:(int)rgbValue
{
    return [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0f green:((float)((rgbValue & 0xFF00) >> 8))/255.0f blue:((float)(rgbValue & 0xFF))/255.0f alpha:1.0f];
}

@end
