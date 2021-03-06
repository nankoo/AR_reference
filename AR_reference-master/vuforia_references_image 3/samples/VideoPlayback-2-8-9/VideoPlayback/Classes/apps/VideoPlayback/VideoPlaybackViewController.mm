/*==============================================================================
 Copyright (c) 2012-2013 Qualcomm Connected Experiences, Inc.
 All Rights Reserved.
 ==============================================================================*/

#import "VideoPlaybackViewController.h"
#import <QCAR/QCAR.h>
#import <QCAR/TrackerManager.h>
#import <QCAR/ImageTracker.h>
#import <QCAR/DataSet.h>
#import <QCAR/Trackable.h>
#import <QCAR/CameraDevice.h>

@interface VideoPlaybackViewController ()

@end

@implementation VideoPlaybackViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    NSLog(@"番号23");
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        NSLog(@"番号23a");
        vapp = [[SampleApplicationSession alloc] initWithDelegate:self];
        
        //最初の画面
        // Custom initialization
        self.title = @"Vuforia";
        // Create the EAGLView with the screen dimensions
        CGRect screenBounds = [[UIScreen mainScreen] bounds];
        viewFrame = screenBounds;
        
        // If this device has a retina display, scale the view bounds that will
        // be passed to QCAR; this allows it to calculate the size and position of
        // the viewport correctly when rendering the video background
        if (YES == vapp.isRetinaDisplay) {
            viewFrame.size.width *= 2.0;
            viewFrame.size.height *= 2.0;
        }
        
        ///////////////img
        dataSetCurrent = nil;
        extendedTrackingIsOn = NO;
        
        // a single tap will trigger a single autofocus operation
        //（下記メソッドを実行するとタップすると動画を再生できなくなる）
        //tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(autofocus:)];
        
        // we use the iOS notification to pause/resume the AR when the application goes (or comeback from) background
        backgroundObserver = [[NSNotificationCenter defaultCenter]
                              addObserverForName:UIApplicationWillResignActiveNotification
                              object:nil
                              queue:nil
                              usingBlock:^(NSNotification *note) {
                                  NSError * error = nil;
                                  if (![vapp pauseAR:&error]) {
                                      NSLog(@"Error pausing AR:%@", [error description]);
                                  }
                              } ];
        
        activeObserver = [[NSNotificationCenter defaultCenter]
                          addObserverForName:UIApplicationDidBecomeActiveNotification
                          object:nil
                          queue:nil
                          usingBlock:^(NSNotification *note) {
                              NSError * error = nil;
                              if(! [vapp resumeAR:&error]) {
                                  NSLog(@"Error resuming AR:%@", [error description]);
                              }
                              // on resume, we reset the flash and the associated menu item
                              QCAR::CameraDevice::getInstance().setFlashTorchMode(false);
                              SampleAppMenu * menu = [SampleAppMenu instance];
                              [menu setSelectionValueForCommand:C_FLASH value:false];
                              
                          } ];
        ///////////////////

    }
    return self;
}


- (void)dealloc
{
    NSLog(@"番号24");
    [[NSNotificationCenter defaultCenter] removeObserver:backgroundObserver];
    [[NSNotificationCenter defaultCenter] removeObserver:activeObserver];
    
    [vapp release];
    [eaglView release];
    
    [super dealloc];
}

- (void)loadView
{
    NSLog(@"番号25");
    // Create the EAGLView
    eaglView = [[[VideoPlaybackEAGLView alloc] initWithFrame:viewFrame  rootViewController:self appSession:vapp] autorelease];
    [self setView:eaglView];
    
    CGRect mainBounds = [[UIScreen mainScreen] bounds];
    CGRect indicatorBounds = CGRectMake(mainBounds.size.width / 2 - 12,
                                        mainBounds.size.height / 2 - 12, 24, 24);
    //インディケーター
    UIActivityIndicatorView *loadingIndicator = [[[UIActivityIndicatorView alloc]
                                          initWithFrame:indicatorBounds]autorelease];
    loadingIndicator.tag  = 1;
    loadingIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
    [eaglView addSubview:loadingIndicator];
    [loadingIndicator startAnimating];
    
    
    [vapp initAR:QCAR::GL_20 ARViewBoundsSize:viewFrame.size orientation:UIInterfaceOrientationPortrait];
    
    //NSNotificationCenterの通知要求の登録メソッド
    backgroundObserver = [[NSNotificationCenter defaultCenter]
                          addObserverForName:UIApplicationWillResignActiveNotification
                          object:nil
                          queue:nil
                          usingBlock:^(NSNotification *note) {
                              [eaglView dismissPlayers];
                              NSError * error = nil;
                              if(! [vapp pauseAR:&error]) {
                                  NSLog(@"番号25a");
                                  NSLog(@"Error pausing AR:%@", [error description]);
                              }
                          } ];
    
    activeObserver = [[NSNotificationCenter defaultCenter]
                      addObserverForName:UIApplicationDidBecomeActiveNotification
                      object:nil
                      queue:nil
                      usingBlock:^(NSNotification *note) {
                          [eaglView preparePlayers];
                          NSError * error = nil;
                          if(! [vapp resumeAR:&error]) {
                              NSLog(@"番号25b");
                              NSLog(@"Error resuming AR:%@", [error description]);
                          }
                          // on resume, we reset the flash and the associated menu item
                          QCAR::CameraDevice::getInstance().setFlashTorchMode(false);
                          SampleAppMenu * menu = [SampleAppMenu instance];
                          [menu setSelectionValueForCommand:C_FLASH value:false];
                      } ];
}


- (void)viewDidLoad
{
    NSLog(@"番号26");
    [super viewDidLoad];
    //eaglview
    [eaglView prepare];
    [self prepareMenu];
    
    //サイドメニュー呼び出し
    UITapGestureRecognizer *doubleTap = [[[UITapGestureRecognizer alloc] initWithTarget: self action:@selector(handleDoubleTap:)] autorelease];
    doubleTap.numberOfTapsRequired = 2;
    [self.view addGestureRecognizer:doubleTap];
    
    UITapGestureRecognizer *tap = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)]autorelease];
    tap.delegate = (id<UIGestureRecognizerDelegate>)self;
    [self.view addGestureRecognizer:tap];
    [tap requireGestureRecognizerToFail:doubleTap];


  // Do any additional setup after loading the view.
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    
    ///img（下記メソッドを実行するとタップすると動画を再生できなくなる）
    //[self.view addGestureRecognizer:tapGestureRecognizer];
    /////
}
    
- (void)viewWillDisappear:(BOOL)animated {
    NSLog(@"番号27");
    if (!self.presentedViewController) {
        NSLog(@"番号27a");

        [eaglView dismiss];
        
        [vapp stopAR:nil];
        // Be a good OpenGL ES citizen: now that QCAR is paused and the render
        // thread is not executing, inform the root view controller that the
        // EAGLView should finish any OpenGL ES commands
        [eaglView finishOpenGLESCommands];
    }
}

- (void)finishOpenGLESCommands
{
    NSLog(@"番号28");
    // Called in response to applicationWillResignActive.  Inform the EAGLView
    //閉じるとき
    [eaglView finishOpenGLESCommands];
}


- (void)freeOpenGLESResources
{
    //freeは解放って意味合いってぽい?
    NSLog(@"番号29");
    // Called in response to applicationDidEnterBackground.  Inform the EAGLView
    //
    [eaglView freeOpenGLESResources];
}


- (void)didReceiveMemoryWarning
{
    NSLog(@"番号30");
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// double tap handler
- (void)handleDoubleTap:(UITapGestureRecognizer *)sender {
    NSLog(@"番号31");
    //esglviewをdoubletaouchすると、、
    CGPoint touchPoint = [sender locationInView:eaglView];
    [eaglView handleDoubleTouchPoint:touchPoint];
    
//    [[NSNotificationCenter defaultCenter] postNotificationName:@"double_tap" object:self];
}

// tap handler
- (void)handleTap:(UITapGestureRecognizer *)sender {
    NSLog(@"番号32");
    if (sender.state == UIGestureRecognizerStateEnded) {
        NSLog(@"番号32a");
        // handling code
        CGPoint touchPoint = [sender locationInView:eaglView];
        [eaglView handleTouchPoint:touchPoint];
    }
}

- (void) dimissController:(id) sender {
    NSLog(@"番号33");
    //translucent:全画面表示にする
    self.navigationController.navigationBar.translucent = NO;
    [vapp stopAR:nil];
    // Be a good OpenGL ES citizen: now that QCAR is paused and the render
    // thread is not executing, inform the root view controller that the
    // EAGLView should finish any OpenGL ES commands
    [eaglView finishOpenGLESCommands];
    [self.navigationController popViewControllerAnimated:YES];
}


// Present a view controller using the root view controller (eaglViewController)
- (void)rootViewControllerPresentViewController:(UIViewController*)viewController inContext:(BOOL)currentContext
{
    NSLog(@"番号34");
    if (YES == currentContext) {
        NSLog(@"番号34a");
        // Use UIModalPresentationCurrentContext so the root view is not hidden
        // when presenting another view controller
        [self setModalPresentationStyle:UIModalPresentationCurrentContext];
    }
    else {
        NSLog(@"番号34b");
        // Use UIModalPresentationFullScreen so the presented view controller
        // covers the screen
        [self setModalPresentationStyle:UIModalPresentationFullScreen];
    }
    
    if ([self respondsToSelector:@selector(presentViewController:animated:completion:)]) {
        // iOS > 4
        [self presentViewController:viewController animated:NO completion:nil];
    }
    else {
        // iOS 4
        [self presentModalViewController:viewController animated:NO];
    }
}

// Dismiss a view controller presented by the root view controller
// (eaglViewController)
- (void)rootViewControllerDismissPresentedViewController
{
    NSLog(@"番号35");
    // Dismiss the presented view controller (return to the root view
    // controller)
    if ([self respondsToSelector:@selector(dismissViewControllerAnimated:completion:)]) {
        // iOS > 4
        [self dismissViewControllerAnimated:NO completion:nil];
    }
    else {
        // iOS 4
        [self dismissModalViewControllerAnimated:NO];
    }
}



#pragma mark - SampleApplicationControl
// Initialize the application trackers(@)
- (bool) doInitTrackers {
    NSLog(@"番号36");
    // Initialize the image or marker tracker
    QCAR::TrackerManager& trackerManager = QCAR::TrackerManager::getInstance();
    
    // Image Tracker...
    QCAR::Tracker* trackerBase = trackerManager.initTracker(QCAR::ImageTracker::getClassType());
    if (trackerBase == NULL)
    {
        NSLog(@"番号36a");
        NSLog(@"Failed to initialize ImageTracker.");
        return false;
    }
    NSLog(@"Successfully initialized ImageTracker.");
    return true;
}

// load the data associated to the trackers
//ここでsampleAppicationSessionにロードしたデータを持っていってる
- (bool) doLoadTrackersData {
    NSLog(@"番号37");
    //下記がないとloadAndActivateImageTrackerDataSetのログも非表示
    [self loadAndActivateImageTrackerDataSet:@"test.xml"];
    return YES;
    
    
    /*///img(確認)
    dataSetStonesAndChips = [self loadImageTrackerDataSet:@"StonesAndChips.xml"];
    //dataSetStonesAndChips = [self loadImageTrackerDataSet:@"KawaSample.xml"];
    dataSetTarmac = [self loadImageTrackerDataSet:@"Tarmac.xml"];
    if ((dataSetStonesAndChips == NULL) || (dataSetTarmac == NULL)) {
        NSLog(@"番号25a");
        NSLog(@"Failed to load datasets");
        return NO;
    }
    if (! [self activateDataSet:dataSetStonesAndChips]) {
        NSLog(@"番号25b");
        NSLog(@"Failed to activate dataset");
        return NO;
    }
    */
}


// start the application trackers(「setHint」違う)
- (bool) doStartTrackers {
    NSLog(@"番号38");
    // Set the number of simultaneous trackables to two
    QCAR::setHint(QCAR::HINT_MAX_SIMULTANEOUS_IMAGE_TARGETS, NUM_VIDEO_TARGETS);
    
    QCAR::TrackerManager& trackerManager = QCAR::TrackerManager::getInstance();
    QCAR::Tracker* tracker = trackerManager.getTracker(QCAR::ImageTracker::getClassType());
    if(tracker == 0) {
        NSLog(@"番号38a");
        return false;
    }
    tracker->start();
    return true;
}


// callback called when the initailization of the AR is done
//
- (void) onInitARDone:(NSError *)initError {
    NSLog(@"番号39");
    //AR読み込んでる
    UIActivityIndicatorView *loadingIndicator = (UIActivityIndicatorView *)[eaglView viewWithTag:1];
    [loadingIndicator removeFromSuperview];
    
    if (initError == nil) {
        NSLog(@"番号39a");
        NSError * error = nil;
        [vapp startAR:QCAR::CameraDevice::CAMERA_BACK error:&error];
        
        // by default, we try to set the continuous auto focus mode
        // and we update menu to reflect the state of continuous auto-focus
        bool isContinuousAutofocus = QCAR::CameraDevice::getInstance().setFocusMode(QCAR::CameraDevice::FOCUS_MODE_CONTINUOUSAUTO);
        SampleAppMenu * menu = [SampleAppMenu instance];
        [menu setSelectionValueForCommand:C_AUTOFOCUS value:isContinuousAutofocus];

    } else {
        NSLog(@"番号39b");
        NSLog(@"Error initializing AR:%@", [initError description]);
    }
}

// update from the QCAR loop
//[switch to]のくだり全部違う
- (void) onQCARUpdate: (QCAR::State *) state {
    NSLog(@"番号40");
    ///img
    if (switchToTarmac) {
        NSLog(@"番号28a");
        [self activateDataSet:dataSetTarmac];
        switchToTarmac = NO;
    }
    if (switchToStonesAndChips) {
        NSLog(@"番号28b");
        [self activateDataSet:dataSetStonesAndChips];
        switchToStonesAndChips = NO;
    }
    /////

}

// stop your trackerts
- (bool) doStopTrackers {
    NSLog(@"番号41");
    QCAR::TrackerManager& trackerManager = QCAR::TrackerManager::getInstance();
    QCAR::Tracker* tracker = trackerManager.getTracker(QCAR::ImageTracker::getClassType());
    
    if (NULL == tracker) {
        NSLog(@"番号41a");
        ////img
        tracker->stop();
        ///
        NSLog(@"ERROR: failed to get the tracker from the tracker manager");
        return false;
    }
    
    tracker->stop();
    return true;
}

// unload the data associated to your trackers
- (bool) doUnloadTrackersData {
    NSLog(@"番号42");
    if (dataSet != NULL) {
        NSLog(@"番号42a");
        // Get the image tracker:
        QCAR::TrackerManager& trackerManager = QCAR::TrackerManager::getInstance();
        QCAR::ImageTracker* imageTracker = static_cast<QCAR::ImageTracker*>(trackerManager.getTracker(QCAR::ImageTracker::getClassType()));
        
        if (imageTracker == NULL)
        {
            NSLog(@"番号42aa");
            NSLog(@"Failed to unload tracking data set because the ImageTracker has not been initialized.");
            return false;
        }
        // Deactivate the data set:
        if (!imageTracker->deactivateDataSet(dataSet))
        {
            NSLog(@"番号42ab");
            NSLog(@"Failed to deactivate data set.");
            return false;
        }
        [self deactivateDataSet: dataSetCurrent];
        dataSetCurrent = nil;
        dataSet = NULL;
    }
    return true;
}


//////img<

- (BOOL)activateDataSet:(QCAR::DataSet *)theDataSet
{
    NSLog(@"番号32");
    // if we've previously recorded an activation, deactivate it
    if (dataSetCurrent != nil)
    {
        NSLog(@"番号33");
        [self deactivateDataSet:dataSetCurrent];
    }
    BOOL success = NO;
    
    // Get the image tracker:
    QCAR::TrackerManager& trackerManager = QCAR::TrackerManager::getInstance();
    QCAR::ImageTracker* imageTracker = static_cast<QCAR::ImageTracker*>(trackerManager.getTracker(QCAR::ImageTracker::getClassType()));
    
    if (imageTracker == NULL) {
        NSLog(@"番号34a");
        NSLog(@"Failed to load tracking data set because the ImageTracker has not been initialized.");
    }
    else
    {
        NSLog(@"番号34b");
        // Activate the data set:
        if (!imageTracker->activateDataSet(theDataSet))
        {
            NSLog(@"番号34ba");
            NSLog(@"Failed to activate data set.");
        }
        else
        {
            NSLog(@"番号34bb");
            NSLog(@"Successfully activated data set.");
            dataSetCurrent = theDataSet;
            success = YES;
        }
    }
    // we set the off target tracking mode to the current state
    if (success) {
        NSLog(@"番号35");
        [self setExtendedTrackingForDataSet:dataSetCurrent start:extendedTrackingIsOn];
    }
    return success;
}


- (BOOL)deactivateDataSet:(QCAR::DataSet *)theDataSet
{
    NSLog(@"番号36");
    if ((dataSetCurrent == nil) || (theDataSet != dataSetCurrent))
    {
        NSLog(@"番号36a");
        NSLog(@"Invalid request to deactivate data set.");
        return NO;
    }
    BOOL success = NO;
    // we deactivate the enhanced tracking
    [self setExtendedTrackingForDataSet:theDataSet start:NO];
    // Get the image tracker:
    QCAR::TrackerManager& trackerManager = QCAR::TrackerManager::getInstance();
    QCAR::ImageTracker* imageTracker = static_cast<QCAR::ImageTracker*>(trackerManager.getTracker(QCAR::ImageTracker::getClassType()));
    
    if (imageTracker == NULL)
    {
        NSLog(@"番号36ba");
        NSLog(@"Failed to unload tracking data set because the ImageTracker has not been initialized.");
    }
    else
    {
        NSLog(@"番号36bb");
        // Activate the data set:
        if (!imageTracker->deactivateDataSet(theDataSet))
        {
            NSLog(@"番号36bba");
            NSLog(@"Failed to deactivate data set.");
        }
        else
        {
            NSLog(@"番号36bbb");
            success = YES;
        }
    }
    dataSetCurrent = nil;
    return success;
}
//////>img



// deinitialize your trackers
- (bool) doDeinitTrackers {
    NSLog(@"番号43");
    QCAR::TrackerManager& trackerManager = QCAR::TrackerManager::getInstance();
    trackerManager.deinitTracker(QCAR::ImageTracker::getClassType());
    return true;
}


- (void)autofocus:(UITapGestureRecognizer *)sender
{
    NSLog(@"番号44");
    [self performSelector:@selector(cameraPerformAutoFocus) withObject:nil afterDelay:.4];
}


- (void)cameraPerformAutoFocus
{
    NSLog(@"番号45");
    QCAR::CameraDevice::getInstance().setFocusMode(QCAR::CameraDevice::FOCUS_MODE_TRIGGERAUTO);
}


///(img)確認１
- (QCAR::DataSet *)loadImageTrackerDataSet:(NSString*)dataFile
{
    NSLog(@"番号29_img");
    NSLog(@"loadImageTrackerDataSet (%@)", dataFile);
    dataSet = NULL;
    
    // Get the QCAR tracker manager image tracker
    QCAR::TrackerManager& trackerManager = QCAR::TrackerManager::getInstance();
    QCAR::ImageTracker* imageTracker = static_cast<QCAR::ImageTracker*>(trackerManager.getTracker(QCAR::ImageTracker::getClassType()));
    
    if (NULL == imageTracker) {
        
        NSLog(@"番号29a_img");
        NSLog(@"ERROR: failed to get the ImageTracker from the tracker manager");
        return NULL;
    } else {
        
        NSLog(@"番号29b_img");
        dataSet = imageTracker->createDataSet();
        
        if (NULL != dataSet) {
            NSLog(@"番号29ba_img");
            NSLog(@"INFO: successfully loaded data set");
            
            // Load the data set from the app's resources location
            if (!dataSet->load([dataFile cStringUsingEncoding:NSASCIIStringEncoding], QCAR::DataSet::STORAGE_APPRESOURCE)) {
                NSLog(@"番号29baa_img");
                NSLog(@"ERROR: failed to load data set");
                imageTracker->destroyDataSet(dataSet);
                dataSet = NULL;
            }
        }
        else {
            NSLog(@"番号29bb_img");
            NSLog(@"ERROR: failed to create data set");
        }
    }
    
    return dataSet;
}
////



// Load the image tracker data set(video)確認２
- (BOOL)loadAndActivateImageTrackerDataSet:(NSString*)dataFile
{
    NSLog(@"番号46");
    NSLog(@"loadAndActivateImageTrackerDataSet (%@)", dataFile);
    BOOL ret = YES;
    dataSet = NULL;
    ///img
    //dataSetTarmac = NULL;
    ///
    
    
    // Get the QCAR tracker manager image tracker
    QCAR::TrackerManager& trackerManager = QCAR::TrackerManager::getInstance();
    //ここで読み込んでる
    QCAR::ImageTracker* imageTracker = static_cast<QCAR::ImageTracker*>(trackerManager.getTracker(QCAR::ImageTracker::getClassType()));
    
    if (NULL == imageTracker) {
        NSLog(@"番号46a");
        NSLog(@"ERROR: failed to get the ImageTracker from the tracker manager");
        ret = NO;
    } else {
        NSLog(@"番号46b");
        //どういう意味？（疑問）
        dataSet = imageTracker->createDataSet();
        ///img
        dataSetTarmac = imageTracker->createDataSet();
        ///
        
        if (NULL != dataSet) {
            NSLog(@"番号46ba");
            NSLog(@"INFO: successfully loaded data set");
            
            // Load the data set from the app's resources location
            if (!dataSet->load([dataFile cStringUsingEncoding:NSASCIIStringEncoding], QCAR::DataSet::STORAGE_APPRESOURCE)) {
                NSLog(@"番号46baa");
                NSLog(@"ERROR: failed to load data set");
                imageTracker->destroyDataSet(dataSet);
                dataSet = NULL;
                ret = NO;
            } else {
                NSLog(@"番号46bab");
                // Activate the data set
                if (imageTracker->activateDataSet(dataSet)) {
                    NSLog(@"番号46baba");
                    NSLog(@"INFO: successfully activated data set");
                }
                else {
                    NSLog(@"番号46babb");
                    NSLog(@"ERROR: failed to activate data set");
                    ret = NO;
                }
            }
        }
        else {
            NSLog(@"番号46bb");
            NSLog(@"ERROR: failed to create data set");
            ret = NO;
        }
    }
    return ret;
}



//画面に収まりきらないオブジェクトの場合
- (BOOL) setExtendedTrackingForDataSet:(QCAR::DataSet *)theDataSet start:(BOOL) start {
    NSLog(@"番号47");
    BOOL result = YES;
    for (int tIdx = 0; tIdx < theDataSet->getNumTrackables(); tIdx++) {
        NSLog(@"番号47for");
        QCAR::Trackable* trackable = theDataSet->getTrackable(tIdx);
        if (start) {
            NSLog(@"番号47for:(if)a");
            if (!trackable->startExtendedTracking())
            {
                NSLog(@"Failed to start extended tracking on: %s", trackable->getName());
                result = false;
            }
        } else {
            NSLog(@"番号47for:(if)b");
            if (!trackable->stopExtendedTracking())
            {
                NSLog(@"Failed to stop extended tracking on: %s", trackable->getName());
                result = false;
            }
        }
    }
    return result;
}




#pragma mark - left menu

//
typedef enum {
    C_EXTENDED_TRACKING,
    C_AUTOFOCUS,
    C_FLASH,
    C_CAMERA_FRONT,
    C_CAMERA_REAR,
    ///img
    SWITCH_TO_TARMAC,
    SWITCH_TO_STONES_AND_CHIPS,
    ///
} MENU_COMMAND;

- (void) prepareMenu {
    NSLog(@"番号48");
    
    SampleAppMenu * menu = [SampleAppMenu prepareWithCommandProtocol:self title:@"vuforia_sub"];
    SampleAppMenuGroup * group;
    
    group = [menu addGroup:@""];
    [group addTextItem:@"About" command:-1];

    group = [menu addGroup:@""];
    [group addSelectionItem:@"Extended Tracking" command:C_EXTENDED_TRACKING isSelected:NO];
    [group addSelectionItem:@"Autofocus" command:C_AUTOFOCUS isSelected:true];
    [group addSelectionItem:@"Flash" command:C_FLASH isSelected:false];
    
    group = [menu addSelectionGroup:@"CAMERA"];
    [group addSelectionItem:@"Front" command:C_CAMERA_FRONT isSelected:false];
    [group addSelectionItem:@"Rear" command:C_CAMERA_REAR isSelected:true];
    
    group = [menu addSelectionGroup:@"DATABASE"];
    [group addSelectionItem:@"Stones & Chips" command:SWITCH_TO_STONES_AND_CHIPS isSelected:YES];
    //[group addSelectionItem:@"Tarmac" command:SWITCH_TO_TARMAC isSelected:NO];
}

- (bool) menuProcess:(SampleAppMenu *) menu command:(int) command value:(bool) value{
    
    NSLog(@"番号49");
    bool result = true;
    NSError * error = nil;

    switch(command) {
            NSLog(@"番号49switch");
        case C_FLASH:
            if (!QCAR::CameraDevice::getInstance().setFlashTorchMode(value)) {
                NSLog(@"番号49switch:a");
                result = false;
            }
            break;
            
        case C_EXTENDED_TRACKING:
            result = [self setExtendedTrackingForDataSet:dataSet start:value];
            NSLog(@"番号49switch:b");
            break;
            
        case C_AUTOFOCUS: {
            NSLog(@"番号49switch:c");
            int focusMode = value ? QCAR::CameraDevice::FOCUS_MODE_CONTINUOUSAUTO : QCAR::CameraDevice::FOCUS_MODE_NORMAL;
            result = QCAR::CameraDevice::getInstance().setFocusMode(focusMode);
        }
            break;
            
        case C_CAMERA_FRONT:
        case C_CAMERA_REAR: {
            NSLog(@"番号49switch:d");
            if ([vapp stopCamera:&error]) {
                result = [vapp startAR:(command == C_CAMERA_FRONT) ? QCAR::CameraDevice::CAMERA_FRONT:QCAR::CameraDevice::CAMERA_BACK error:&error];
            } else {
                result = false;
            }
        }
            break;
            
        //case SWITCH_TO_TARMAC:
            NSLog(@"番号42c:case SWITCH_TO_TARMAC:");
            [self setExtendedTrackingForDataSet:dataSetCurrent start:NO];
            switchToTarmac = YES;
            switchToStonesAndChips = NO;
            break;
            
        case SWITCH_TO_STONES_AND_CHIPS:
            NSLog(@"番号42c:case SWITCH_TO_STONES_AND_CHIPS:");
            [self setExtendedTrackingForDataSet:dataSetCurrent start:NO];
            switchToStonesAndChips = YES;
            switchToTarmac = NO;
            break;

            
        default:
            result = false;
            break;
    }
    return result;
}

@end

