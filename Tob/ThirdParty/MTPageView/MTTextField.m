//
//  MTTextField.m
//  MTPageView
//
//  Created by Jean-Romain on 16/07/2017.
//  Copyright © 2017 JustKodding. All rights reserved.
//

#import "MTTextField.h"
#import "MTNavigationBar.h"
#import <QuartzCore/QuartzCore.h>

@implementation MTTextField

- (id)init {
    self = [super init];
    
    if (self) {
        [self initContent];
    }
    
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (self) {
        [self initContent];
    }
    
    return self;
}

- (void)initContent {
    [self setClearButtonMode:UITextFieldViewModeWhileEditing];
    [self setBorderStyle:UITextBorderStyleNone];
    [self setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];
    [self setAdjustsFontSizeToFitWidth:YES];
    [self.layer setCornerRadius:kTextFieldCornerRadius];
    [self.layer setBorderColor:[UIColor colorWithWhite:0.8 alpha:1.0].CGColor];
    [self.layer setBorderWidth:1.0];
    [self.layer setMasksToBounds:YES];

    [self setNeedsDisplay];
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    
    float alpha = 1.0f;
    
    if (frame.size.height <= [self maxHeight]) {
        // Navigation bar is being hidden
        alpha = (frame.size.height - kMinTextFieldHeight) / ([self maxHeight] - kMinTextFieldHeight);
    } else {
        // Shortcuts are being shown
        alpha = 1 - (frame.size.height - [self maxHeight]) / ([self transitionHeight] - [self maxHeight]);
    }
    
    alpha = MAX(0, MIN(1, alpha));
    
    if (!self.isFirstResponder) {
        [self setAlpha:alpha];
    }
}

- (float)maxHeight {
    return [(MTNavigationBar *)self.superview maxHeight] - 2 * kNavBarTopDownMargin - [(MTNavigationBar *)self.superview statusBarHeight];
}

- (float)transitionHeight {
    return [(MTNavigationBar *)self.superview shortcutBeginAppearingHeight] - 2 * kNavBarTopDownMargin - [(MTNavigationBar *)self.superview statusBarHeight];
}

- (void)restoreSavedText {
    [self setText:_savedText];
}

@end
