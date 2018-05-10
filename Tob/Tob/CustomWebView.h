//
//  CustomWebView.h
//  Tob
//
//  Created by Jean-Romain on 26/04/2016.
//  Copyright © 2016 JustKodding. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TabsViewController.h"
#import <QuartzCore/QuartzCore.h>

@class TabsViewController;

@interface CustomWebView : UIWebView <UIWebViewDelegate, UIAlertViewDelegate, UIGestureRecognizerDelegate> {
    UIDocumentInteractionController *_docController;
    UIView *_openPdfView;
    UIButton *_openPDFButton;
}

@property (nonatomic, strong) NSURL *url;
@property (nonatomic) BOOL needsForceRefresh;
@property (nonatomic) float progress;
@property int TLSStatus;

- (void)setParent:(TabsViewController *)parent;
- (void)updateTLSStatus:(Byte)newStatus;

@end
