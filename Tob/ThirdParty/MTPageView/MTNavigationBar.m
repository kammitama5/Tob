//
//  MTNavigationBar.m
//  MTPageView
//
//  Created by Jean-Romain on 16/07/2017.
//  Copyright © 2017 JustKodding. All rights reserved.
//

#import "MTNavigationBar.h"
#import "MTTextField.h"
#import "CustomWebView.h"
#import "AppDelegate.h"
#import <QuartzCore/QuartzCore.h>

@implementation MTNavigationBar {
    BOOL shortcutsAreVisible;
    BOOL shortcutsAreSelectable;
    BOOL shortcutDidTrigger;
    
    UIView *_shortcutsView;
    UIView *_shortcutSelectorView;
    UIButton *_closeButton;
    UIButton *_refreshButton;
    UIButton *_newTabButton;
    int selectedShortcutIndex;
    
    CGPoint _initialTouchLocation;
}

- (id)init {
    self = [super init];
    
    if (self) {
        [self initItems];
    }
    
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (self) {
        [self initItems];
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        [self initItems];
    }
    
    return self;
}

- (void)initItems {    
    // Add a custom cancel button to the navigation bar
    self.cancelButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.cancelButton addTarget:self action:@selector(cancelAction) forControlEvents:UIControlEventTouchUpInside];
    [self.cancelButton setTitle:NSLocalizedString(@"Cancel", nil) forState:UIControlStateNormal];
    [self.cancelButton setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin];
    [self addSubview:self.cancelButton];
    [self.cancelButton sizeToFit];
    [self.cancelButton setFrame:CGRectMake(self.frame.size.width - self.cancelButton.frame.size.width - kNavBarSideMargin, kNavBarTopDownMargin, self.cancelButton.frame.size.width, kNavBarMaxHeight - 2 * kNavBarTopDownMargin)];
    
    // Use a custom title field for the navigation bar
    _textField = [[MTTextField alloc] initWithFrame:CGRectMake(kNavBarSideMargin, kNavBarTopDownMargin + self.statusBarHeight, self.frame.size.width - self.cancelButton.frame.size.width - 3 * kNavBarSideMargin, self.frame.size.height - 2 * kNavBarTopDownMargin - self.statusBarHeight)];
    [self.textField setBackgroundColor:[UIColor whiteColor]];
    [self.textField setClearButtonMode:UITextFieldViewModeWhileEditing];
    [self.textField setDelegate:self];
    [self addSubview:self.textField];
    
    // Add a progress view to the naivgation bar
    _progressView = [[UIProgressView alloc] init];
    [_progressView setFrame:CGRectMake(0, self.frame.size.height, self.frame.size.width, _progressView.frame.size.height)];
    [_progressView setAutoresizingMask:UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth];
    [self addSubview:_progressView];
    
    // Create a view with shortcuts
    _shortcutsView = [[UIView alloc] initWithFrame:self.frame];
    [_shortcutsView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    [_shortcutsView setBackgroundColor:[UIColor clearColor]];
    [self createShortcuts];
    [self addSubview:_shortcutsView];
    
    // Add a shadow
    [self.layer setShadowColor:[UIColor grayColor].CGColor];
    [self.layer setShadowOffset:CGSizeMake(0, 0)];
    [self.layer setShadowOpacity:1.0f];
    [self.layer setShadowRadius:0.5f];
    [self setClipsToBounds:NO];

    shortcutsAreVisible = NO;
    shortcutsAreSelectable = NO;
    shortcutDidTrigger = NO;
    _initialTouchLocation = CGPointZero;
    selectedShortcutIndex = 1;
    [self hideCancelButtonAnimated:NO];
}

- (void)createShortcuts {
    float spacing = (self.frame.size.width - 3 * kNavBarShortcutButtonSize) / 4;
    float yPosition = (_shortcutsView.frame.size.height - kNavBarShortcutButtonSize) / 2;
    
    _closeButton =  [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *closeImage = [[UIImage imageNamed:@"StopLoading"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [_closeButton setImage:closeImage forState:UIControlStateNormal];
    [_closeButton setBackgroundColor:[UIColor clearColor]];
    [_closeButton setTintColor:self.tintColor];
    [_closeButton setFrame:CGRectMake(spacing, yPosition, kNavBarShortcutButtonSize, kNavBarShortcutButtonSize)];
    [_closeButton setAutoresizingMask:UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin];

    _refreshButton =  [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *refreshImage = [[UIImage imageNamed:@"Reload"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [_refreshButton setImage:refreshImage forState:UIControlStateNormal];
    [_refreshButton setBackgroundColor:[UIColor clearColor]];
    [_refreshButton setTintColor:self.tintColor];
    [_refreshButton setFrame:CGRectMake(2 * spacing + kNavBarShortcutButtonSize, yPosition, kNavBarShortcutButtonSize, kNavBarShortcutButtonSize)];
    [_refreshButton setAutoresizingMask:UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin];

    _newTabButton =  [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *newTabImage = [[UIImage imageNamed:@"AddPage"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [_newTabButton setImage:newTabImage forState:UIControlStateNormal];
    [_newTabButton setBackgroundColor:[UIColor clearColor]];
    [_newTabButton setTintColor:self.tintColor];
    [_newTabButton setFrame:CGRectMake(3 * spacing + 2 * kNavBarShortcutButtonSize, yPosition, kNavBarShortcutButtonSize, kNavBarShortcutButtonSize)];
    [_newTabButton setAutoresizingMask:UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin];

    _shortcutSelectorView = [[UIView alloc] initWithFrame: _refreshButton.frame];
    [_shortcutSelectorView setBackgroundColor:self.tintColor];
    [_shortcutSelectorView.layer setCornerRadius:kNavBarShortcutButtonSize / 2];
    [_shortcutSelectorView setClipsToBounds:YES];

    [_shortcutsView addSubview:_shortcutSelectorView];
    [_shortcutsView addSubview:_newTabButton];
    [_shortcutsView addSubview:_refreshButton];
    [_shortcutsView addSubview:_closeButton];
}

- (void)cancelAction {
    [self.textField restoreSavedText];
    [self.textField resignFirstResponder];
}

- (void)closeAction {
    [self.parent closeCurrentTabAndSelectNext];
}

- (void)refreshAction {
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    CustomWebView *webView = [[appDelegate.tabsViewController contentViews] objectAtIndex:[self.parent currentIndex]];
    [webView reload];
    
    CABasicAnimation *rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation.toValue = [NSNumber numberWithFloat:2 * M_PI];
    rotationAnimation.duration = kNavBarShortcutSelectionConfirmationAnimationDuration;
    rotationAnimation.cumulative = YES;
    rotationAnimation.repeatCount = 1;
    [_refreshButton.layer addAnimation:rotationAnimation forKey:@"rotationAnimation"];
}

- (void)newTabAction {
    [self.parent addTab];
}

- (void)showCancelButton {
    [self showCancelButtonAnimated:YES];
}

- (void)showCancelButtonAnimated:(BOOL)animated {
    [UIView animateWithDuration:kCancelButtonAnimationDuration * animated animations:^{
        [self.cancelButton setAlpha:1];
        [self.textField setFrame:CGRectMake(self.textField.frame.origin.x, self.textField.frame.origin.y, self.frame.size.width - self.cancelButton.frame.size.width - 3 * kNavBarSideMargin, self.textField.frame.size.height)];
    }];
}

- (void)hideCancelButton {
    [self hideCancelButtonAnimated:YES];
}

- (void)hideCancelButtonAnimated:(BOOL)animated {
    [UIView animateWithDuration:kCancelButtonAnimationDuration * animated animations:^{
        [self.cancelButton setAlpha:0];
        [self.textField setFrame:CGRectMake(kNavBarSideMargin, self.textField.frame.origin.y, self.frame.size.width - 2 * kNavBarSideMargin, self.textField.frame.size.height)];
    }];
}

- (void)finishSelectingShortcut {
    if (!shortcutsAreSelectable || shortcutDidTrigger) {
        return;
    }
    
    if (selectedShortcutIndex == 0) {
        // Select left shortcut
        [self closeAction];
    } else if (selectedShortcutIndex == 1) {
        // Select middle shortcut
        [self refreshAction];
    } else if (selectedShortcutIndex == 2) {
        // Select right shortcut
        [self newTabAction];
    }
    shortcutDidTrigger = YES;
    shortcutsAreSelectable = NO;
}

- (float)statusBarHeight {
    // [UIApplication sharedApplication].statusBarFrame.size.height doesn't always give the right height when and orientation just changed or when in call
    if ([UIApplication sharedApplication].statusBarFrame.size.height == 40) {
        // Phone-call bar is displayed
        return [UIApplication sharedApplication].statusBarFrame.size.height / 2;
    } else if ((UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation]) || UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)) {
        // Status bar is displayed full height
        return [UIApplication sharedApplication].statusBarFrame.size.height;
    } else {
        // status bar should be hidden
        return 0;
    }
}

- (float)maxHeight {
    return kNavBarMaxHeight + [self statusBarHeight];
}

- (float)minHeight {
    return kNavBarMinHeight + [self statusBarHeight];
}

- (float)shortcutBeginAppearingHeight {
    return kNavBarShortcutBeginAppearingHeight + [self statusBarHeight];
}

- (float)shortcutIconsEndAppearingHeight {
    return kNavBarShortcutIconsEndAppearingHeight + [self statusBarHeight];
}

- (float)shortcutSelectorEndAppearingHeight {
    return kNavBarShortcutSelectorEndAppearingHeight + [self statusBarHeight];
}

- (void)setTextField:(MTTextField *)textField {
    CGRect frame = self.textField.frame;
    [self.textField removeFromSuperview];
    _textField = nil;
    
    _textField = textField;
    [self addSubview:self.textField];
    [self.textField setFrame:frame];
    [self.textField setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    [self.textField setDelegate:self];
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    
    if (self.cancelButton.alpha > 0) {
        [self.textField setFrame:CGRectMake(kNavBarSideMargin, kNavBarTopDownMargin + self.statusBarHeight, self.frame.size.width - self.cancelButton.frame.size.width - 3 * kNavBarSideMargin, self.frame.size.height - 2 * kNavBarTopDownMargin - self.statusBarHeight)];
    } else {
        [self.textField setFrame:CGRectMake(kNavBarSideMargin, kNavBarTopDownMargin + self.statusBarHeight, self.frame.size.width - 2 * kNavBarSideMargin, self.frame.size.height - 2 * kNavBarTopDownMargin - self.statusBarHeight)];
    }
    
    if (frame.size.height > self.shortcutBeginAppearingHeight) {
        shortcutsAreVisible = YES;

        float alpha = (frame.size.height - self.shortcutBeginAppearingHeight) / (self.shortcutIconsEndAppearingHeight - self.shortcutBeginAppearingHeight);
        alpha = MIN(1, alpha);
        
        if (!shortcutsAreSelectable) {
            float progress = 1 - (self.shortcutSelectorEndAppearingHeight - frame.size.height) / (self.shortcutSelectorEndAppearingHeight - self.shortcutIconsEndAppearingHeight);
            progress = MAX(0, MIN(1, progress));
            
            [_shortcutSelectorView setBackgroundColor:self.tintColor];
            [_shortcutSelectorView setCenter:CGPointMake(_shortcutSelectorView.center.x, progress * (_refreshButton.center.y + kNavBarShortcutButtonSize) - kNavBarShortcutButtonSize)];
            
            if (progress > 0.8) {
                [_refreshButton setTintColor:self.backgroundColor];
            } else {
                [_refreshButton setTintColor:self.tintColor];
            }
            
            if (progress == 1) {
                _initialTouchLocation = _touchLocation;
                shortcutsAreSelectable = YES;
            }
        } else {
            [_shortcutSelectorView setCenter:CGPointMake(_shortcutSelectorView.center.x, _refreshButton.center.y)];
        }
        
        [_shortcutsView setAlpha:alpha];
    } else {
        [_shortcutSelectorView setCenter:CGPointMake(_refreshButton.center.x, -kNavBarShortcutButtonSize)];
        [_closeButton setTintColor:self.tintColor];
        [_refreshButton setTintColor:self.tintColor];
        [_newTabButton setTintColor:self.tintColor];
        [_shortcutsView setAlpha:0];

        shortcutsAreVisible = NO;
        shortcutsAreSelectable = NO;
        shortcutDidTrigger = NO;
        _initialTouchLocation = CGPointZero;
        _touchLocation = CGPointZero;
        selectedShortcutIndex = 1;
    }
}

- (void)setTouchLocation:(CGPoint)touchLocation {
    _touchLocation = touchLocation;

    if (!shortcutsAreSelectable) {
        return;
    }
    
    [_shortcutSelectorView setCenter:CGPointMake(_shortcutSelectorView.center.x, _refreshButton.center.y)];
    
    // Find the farthest point from the center that the user reached
    if (touchLocation.x < _initialTouchLocation.x && _closeButton.tintColor == self.backgroundColor) {
        _initialTouchLocation = touchLocation;
    } else if (touchLocation.x > _initialTouchLocation.x && _newTabButton.tintColor == self.backgroundColor) {
        _initialTouchLocation = touchLocation;
    }
    
    float spacing = (self.frame.size.width - 3 * kNavBarShortcutButtonSize) / 4;
    float movementToSwitch = spacing + kNavBarShortcutButtonSize / 2;
    float movement = touchLocation.x - _initialTouchLocation.x;
    
    if (movement < -movementToSwitch && selectedShortcutIndex == 1) {
        // Moved left enough compared to the center shortcut, highlight left shortcut
        _initialTouchLocation = touchLocation;
        selectedShortcutIndex = 0;
        
        [UIView animateWithDuration:kNavBarShortcutSelectionChangeAnimationDuration delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            [_shortcutSelectorView setFrame:_closeButton.frame];
            [_closeButton setTintColor:self.backgroundColor];
            [_refreshButton setTintColor:self.tintColor];
            [_newTabButton setTintColor:self.tintColor];
        } completion:nil];
    } else if (movement > movementToSwitch && selectedShortcutIndex == 1) {
        // Moved right enough compared to the center shortcut, highlight right shortcut
        _initialTouchLocation = touchLocation;
        selectedShortcutIndex = 2;
        
        [UIView animateWithDuration:kNavBarShortcutSelectionChangeAnimationDuration delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            [_shortcutSelectorView setFrame:_newTabButton.frame];
            [_newTabButton setTintColor:self.backgroundColor];
            [_closeButton setTintColor:self.tintColor];
            [_refreshButton setTintColor:self.tintColor];
        } completion:nil];
    } else if (CGPointEqualToPoint(_initialTouchLocation, CGPointZero) || (movement > movementToSwitch && selectedShortcutIndex == 0) || (movement < -movementToSwitch && selectedShortcutIndex == 2)) {
        // Didn't select any shortcut yet or moved right enough compared to the left shortcut or left enough compared to the right shortcut, highlight left shortcut
        _initialTouchLocation = touchLocation;
        selectedShortcutIndex = 1;
        
        [UIView animateWithDuration:kNavBarShortcutSelectionChangeAnimationDuration delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            [_shortcutSelectorView setFrame:_refreshButton.frame];
            [_refreshButton setTintColor:self.backgroundColor];
            [_closeButton setTintColor:self.tintColor];
            [_newTabButton setTintColor:self.tintColor];
        } completion:nil];
    }
}


#pragma mark - UITextField delegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    [self showCancelButton];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [self hideCancelButton];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self.textField resignFirstResponder];
    return YES;
}

@end
