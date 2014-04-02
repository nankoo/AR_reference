/*==============================================================================
 Copyright (c) 2012-2013 Qualcomm Connected Experiences, Inc.
 All Rights Reserved.
 ==============================================================================*/

#import <UIKit/UIKit.h>

@class SampleAppLeftMenuViewController;

@interface SampleAppSlidingMenuController : UIViewController <UIGestureRecognizerDelegate>{
    
    // we keep track of the gestu recognizer in order to be able to enable/disable them
    //タップ
    UITapGestureRecognizer * tapGestureRecognizer;
    //スワイプ
    UIPanGestureRecognizer * panGestureRecognizer;
    
    CGFloat kSlidingMenuWidth;
    BOOL ignoreDoubleTap;
    
    // true when the left menu is displayed
    BOOL showingLeftMenu;
}

- (id)initWithRootViewController:(UIViewController*)controller;

- (void) shouldIgnoreDoubleTap;
- (void) showRootController:(BOOL)animated;
- (void) showLeftMenu:(BOOL)animated;

- (void) dismiss;


- (void)setRootViewControllerShadow:(BOOL)val;

@property(nonatomic,strong) SampleAppLeftMenuViewController *menuViewController;
@property(nonatomic,strong) UIViewController *rootViewController;

@end

