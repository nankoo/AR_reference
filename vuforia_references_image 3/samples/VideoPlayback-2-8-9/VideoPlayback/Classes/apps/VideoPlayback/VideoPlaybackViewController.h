/*==============================================================================
 Copyright (c) 2012-2013 Qualcomm Connected Experiences, Inc.
 All Rights Reserved.
 ==============================================================================*/

#import <UIKit/UIKit.h>
#import "SampleAppMenu.h"
#import "VideoPlaybackEAGLView.h"
#import "SampleApplicationSession.h"
#import <QCAR/DataSet.h>

@interface VideoPlaybackViewController : UIViewController <SampleApplicationControl, SampleAppMenuCommandProtocol>{
    CGRect viewFrame;
    VideoPlaybackEAGLView* eaglView;
    SampleApplicationSession * vapp;
    
    id backgroundObserver;
    id activeObserver;
    
    
    QCAR::DataSet*  dataSet;
    ////img
    QCAR::DataSet*  dataSetCurrent;
    QCAR::DataSet*  dataSetTarmac;
    QCAR::DataSet*  dataSetStonesAndChips;
    UITapGestureRecognizer * tapGestureRecognizer;
    
    BOOL switchToTarmac;
    BOOL switchToStonesAndChips;
    BOOL extendedTrackingIsOn;
    ////
}

- (void)rootViewControllerPresentViewController:(UIViewController*)viewController inContext:(BOOL)currentContext;
- (void)rootViewControllerDismissPresentedViewController;

@end
