//
//  MTNavigationBar.h
//  MTPageView
//
//  Created by Jean-Romain on 16/07/2017.
//  Copyright © 2017 JustKodding. All rights reserved.
//

#import "MTPageViewController.h"
#import <UIKit/UIKit.h>

@class MTTextField;
@class MTPageViewController;

static const CGFloat kNavBarTopDownMargin = 5.0f;
static const CGFloat kNavBarSideMargin = 5.0f;
static const CGFloat kNavBarShortcutButtonSize = 40.0f;

static const CGFloat kCancelButtonAnimationDuration = 0.3f;
static const CGFloat kNavBarShortcutSelectionChangeAnimationDuration = 0.12f;
static const CGFloat kNavBarShortcutSelectionConfirmationAnimationDuration = 0.4f;

static const CGFloat kNavBarMinHeight = 0.0f;
static const CGFloat kNavBarMaxHeight = 44.0f;
static const CGFloat kNavBarShortcutBeginAppearingHeight = 54.0f;
static const CGFloat kNavBarShortcutIconsEndAppearingHeight = 74.0f;
static const CGFloat kNavBarShortcutSelectorEndAppearingHeight = 94.0f;

@interface MTNavigationBar : UIView <UITextFieldDelegate>

@property (nonatomic, strong) MTTextField *textField;
@property (nonatomic, strong) UIButton *cancelButton;
@property (nonatomic, strong) UIProgressView *progressView;
@property (nonatomic, strong) MTPageViewController *parent;

@property (nonatomic) CGPoint touchLocation;

- (void)showCancelButton;
- (void)showCancelButtonAnimated:(BOOL)animated;
- (void)hideCancelButton;
- (void)hideCancelButtonAnimated:(BOOL)animated;

- (void)finishSelectingShortcut;

- (float)maxHeight;
- (float)minHeight;

- (float)shortcutBeginAppearingHeight;

- (float)statusBarHeight;

@end
