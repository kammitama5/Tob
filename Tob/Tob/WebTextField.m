//
//  WebTextField.m
//  MTPageView
//
//  Created by Jean-Romain on 17/07/2017.
//  Copyright © 2017 JustKodding. All rights reserved.
//

#import "WebTextField.h"

@implementation WebTextField

- (id)init {
    self = [super init];
    
    if (self) {
        [self initButtons];
    }
    
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (self) {
        [self initButtons];
    }
    
    return self;
}

- (void)initButtons {
    _savedText = @"";
    
    self.refreshButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.refreshButton setFrame:CGRectMake(0, 0, 29, 29)];
    [self.refreshButton setBackgroundColor:[UIColor clearColor]];
    [self.refreshButton setImage:[[UIImage imageNamed:@"Reload"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [self.refreshButton setTintColor:[UIColor grayColor]];
    
    [self setRightView:self.refreshButton];
    [self setRightViewMode:UITextFieldViewModeUnlessEditing];

    self.stopButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.stopButton setFrame:CGRectMake(0, 0, 29, 29)];
    [self.stopButton setBackgroundColor:[UIColor clearColor]];
    [self.stopButton setImage:[[UIImage imageNamed:@"StopLoading"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [self.stopButton setTintColor:[UIColor grayColor]];

    self.tlsButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.tlsButton setFrame:CGRectMake(0, 0, 29, 29)];
    [self.tlsButton setBackgroundColor:[UIColor clearColor]];
    [self.tlsButton setImage:[[UIImage imageNamed:@"Lock"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [self.tlsButton setTintColor:[UIColor grayColor]];

    [self setLeftView:self.tlsButton];
    [self setLeftViewMode:UITextFieldViewModeUnlessEditing];

    [self.rightView setAutoresizingMask:UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin];
    [self.leftView setAutoresizingMask:UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin];
    
    [self setBackgroundColor:[UIColor whiteColor]];
    [self setAutocapitalizationType:UITextAutocapitalizationTypeNone];
    [self setAutocorrectionType:UITextAutocorrectionTypeNo];
    [self setReturnKeyType:UIReturnKeyGo];
    [self setKeyboardType:UIKeyboardTypeWebSearch];
    [self setAdjustsFontSizeToFitWidth:YES];
    [self setTextAlignment:NSTextAlignmentCenter];
}

- (BOOL)becomeFirstResponder {
    [self setTextAlignment:NSTextAlignmentLeft];
    _savedText = self.text;
    
    return [super becomeFirstResponder];
}

- (BOOL)resignFirstResponder {
    [self setTextAlignment:NSTextAlignmentCenter];

    return [super resignFirstResponder];
}

- (CGRect)textRectForBounds:(CGRect)bounds {
    int margin = 29;
    
    if (self.textAlignment == NSTextAlignmentCenter) {
        CGRect inset = CGRectMake(bounds.origin.x + margin, bounds.origin.y, bounds.size.width - (margin * 2), bounds.size.height);
        return inset;
    } else {
        CGRect inset = CGRectMake(bounds.origin.x + 5, bounds.origin.y, (bounds.size.width - margin) - 5, bounds.size.height);
        return inset;
    }
}

- (CGRect)editingRectForBounds:(CGRect)bounds {
    int margin = 29;
    CGRect inset = CGRectMake(bounds.origin.x + 5, bounds.origin.y, (bounds.size.width - margin) - 5, bounds.size.height);
    return inset;
}

- (void)setClearButtonColor:(UIColor *)color {
    UIButton *clearButton = [self buttonClear];
    UIImage *clearImage = [clearButton imageForState:UIControlStateNormal];
    
    [clearButton setImage:[WebTextField imageWithImage:clearImage tintColor:color] forState:UIControlStateNormal];
}

- (void)setClearButtonHighlightedColor:(UIColor *)color {
    UIButton *clearButton = [self buttonClear];
    UIImage *clearImage = [clearButton imageForState:UIControlStateHighlighted];
    
    [clearButton setImage:[WebTextField imageWithImage:clearImage tintColor:color] forState:UIControlStateHighlighted];
}

- (UIButton *)buttonClear {
    for(UIView *v in self.subviews) {
        if([v isKindOfClass:[UIButton class]]) {
            UIButton *buttonClear = (UIButton *) v;
            return buttonClear;
        }
    }
    return nil;
}

+ (UIImage *)imageWithImage:(UIImage *)image tintColor:(UIColor *)tintColor {
    UIGraphicsBeginImageContextWithOptions(image.size, NO, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGRect rect = (CGRect){ CGPointZero, image.size };
    CGContextSetBlendMode(context, kCGBlendModeNormal);
    [image drawInRect:rect];
    
    CGContextSetBlendMode(context, kCGBlendModeSourceIn);
    [tintColor setFill];
    CGContextFillRect(context, rect);
    
    UIImage *imageTinted  = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return imageTinted;
}

@end
