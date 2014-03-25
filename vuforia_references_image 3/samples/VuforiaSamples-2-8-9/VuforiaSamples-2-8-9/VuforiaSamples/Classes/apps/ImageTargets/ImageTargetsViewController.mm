/*==============================================================================
 Copyright (c) 2012-2013 Qualcomm Connected Experiences, Inc.
 All Rights Reserved.
 ==============================================================================*/

#import "ImageTargetsViewController.h"
#import <QCAR/QCAR.h>
#import <QCAR/TrackerManager.h>
#import <QCAR/ImageTracker.h>
#import <QCAR/Trackable.h>
#import <QCAR/DataSet.h>
#import <QCAR/CameraDevice.h>

@interface ImageTargetsViewController ()

@end

@implementation ImageTargetsViewController{
    
    UIView *hoge;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    NSLog(@"番号14");
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        NSLog(@"番号14a");
        vapp = [[SampleApplicationSession alloc] initWithDelegate:self];
        
        // Custom initialization
        self.title = @"イメージターゲット";
        // Create the EAGLView with the screen dimensions
        CGRect screenBounds = [[UIScreen mainScreen] bounds];
        //トラッカーを読み込む画面の作成
        viewFrame = screenBounds;
        
        // If this device has a retina display, scale the view bounds that will
        // be passed to QCAR; this allows it to calculate the size and position of
        // the viewport correctly when rendering the video background
        if (YES == vapp.isRetinaDisplay) {
            NSLog(@"番号14aa");
            viewFrame.size.width *= 2.0;
            viewFrame.size.height *= 2.0;
        }
        
        dataSetCurrent = nil;
        extendedTrackingIsOn = NO;
        
        // a single tap will trigger a single autofocus operation
        tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(autofocus:)];
        
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
    }
    return self;
}

- (void)dealloc
{
    NSLog(@"番号15");
    [[NSNotificationCenter defaultCenter] removeObserver:backgroundObserver];
    [[NSNotificationCenter defaultCenter] removeObserver:activeObserver];
    [tapGestureRecognizer release];
    
    [vapp release];
    [eaglView release];
    
    [super dealloc];
}

- (void)loadView
{
    NSLog(@"番号16");
    // Create the EAGLView
    eaglView = [[ImageTargetsEAGLView alloc] initWithFrame:viewFrame appSession:vapp];
    [self setView:eaglView];
    
    // show loading animation while AR is being initialized
    [self showLoadingAnimation];
    
    // initialize the AR session
    [vapp initAR:QCAR::GL_20 ARViewBoundsSize:viewFrame.size orientation:UIInterfaceOrientationPortrait];
}



/////////////////////////////////////

- (void)viewDidLoad
{
    NSLog(@"番号17");
    [super viewDidLoad];
    
    
    UIScreen* screen = [UIScreen mainScreen];
    hoge = [[UIView alloc] initWithFrame:CGRectMake(0.0,0.0,screen.bounds.size.width,screen.bounds.size.height)];
    hoge.backgroundColor =  [UIColor whiteColor];
    [self.view addSubview:hoge];
    
    
    /////////////////お遊びサンプル////////////////
    UIAlertView *alert =
    [[UIAlertView alloc] initWithTitle:@"お知らせ" message:@"完了しました"
                              delegate:self cancelButtonTitle:@"確認" otherButtonTitles:nil];
    [alert show];
    
    
    
    /////////////////////////////////
    
    
//    /////////////////お遊びサンプル////////////////
//    UIAlertView *alert =
//    [[UIAlertView alloc] initWithTitle:@"お知らせ" message:@"完了しました"
//                              delegate:self cancelButtonTitle:@"確認" otherButtonTitles:nil];
//    [alert show];
//    
//    
//    
//    /////////////////////////////////
    
    [self prepareMenu];

	// Do any additional setup after loading the view.
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    [self.view addGestureRecognizer:tapGestureRecognizer];
    
    NSLog(@"self.navigationController.navigationBarHidden:%d",self.navigationController.navigationBarHidden);
}


-(void)alertView:(UIAlertView*)alertView
clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    hoge.hidden = YES;
    
}
//////////////////////////


- (void)viewWillDisappear:(BOOL)animated {
    NSLog(@"番号18");
    [vapp stopAR:nil];
    // Be a good OpenGL ES citizen: now that QCAR is paused and the render
    // thread is not executing, inform the root view controller that the
    // EAGLView should finish any OpenGL ES commands
    [eaglView finishOpenGLESCommands];

}

- (void)finishOpenGLESCommands
{
    NSLog(@"番号19");
    // Called in response to applicationWillResignActive.  Inform the EAGLView
    [eaglView finishOpenGLESCommands];
}


- (void)freeOpenGLESResources
{
    NSLog(@"番号20");
    // Called in response to applicationDidEnterBackground.  Inform the EAGLView
    [eaglView freeOpenGLESResources];
}


- (void)didReceiveMemoryWarning
{
    NSLog(@"番号21");
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - loading animation

- (void) showLoadingAnimation {
    NSLog(@"番号22");
    
    CGRect mainBounds = [[UIScreen mainScreen] bounds];
    CGRect indicatorBounds = CGRectMake(mainBounds.size.width / 2 - 12,
                                        mainBounds.size.height / 2 - 12, 24, 24);
    UIActivityIndicatorView *loadingIndicator = [[[UIActivityIndicatorView alloc]
                                                  initWithFrame:indicatorBounds]autorelease];
    
    loadingIndicator.tag  = 1;
    loadingIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
    [eaglView addSubview:loadingIndicator];
    [loadingIndicator startAnimating];
}

- (void) hideLoadingAnimation {
    NSLog(@"番号23");
    UIActivityIndicatorView *loadingIndicator = (UIActivityIndicatorView *)[eaglView viewWithTag:1];
    [loadingIndicator removeFromSuperview];
}


#pragma mark - SampleApplicationControl

- (bool) doInitTrackers {
    NSLog(@"番号24");
    // Initialize the image or marker tracker
    //ここで前述のインスタンス群を取得
    QCAR::TrackerManager& trackerManager = QCAR::TrackerManager::getInstance();
    
    // Image Tracker...
    QCAR::Tracker* trackerBase = trackerManager.initTracker(QCAR::ImageTracker::getClassType());
    if (trackerBase == NULL)
    {
        NSLog(@"番号24a");
        NSLog(@"Failed to initialize ImageTracker.");
        return false;
    }
    NSLog(@"Successfully initialized ImageTracker.");
    return true;
}

- (bool) doLoadTrackersData {
    //トラッカーを読み込む？
    //SDKでvuforiaにデータを送って処理しているからアプリ内のデータは消しても問題無し？
    NSLog(@"番号25");
    //ここのトラッカーだけ変更すると起動しなくなる
    //トラッカーを変更する為には、まずvuforia上で画像のトラッカー申請を行い、番号25にxml形式で記載。その後プロジェクト内にも、xml/datの形で追加すると作業完了。
    //dataSetStonesAndChips = [self loadImageTrackerDataSet:@"StonesAndChips.xml"];
    dataSetStonesAndChips = [self loadImageTrackerDataSet:@"KawaSample.xml"];
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
    
    
    return YES;
}

- (bool) doStartTrackers {
    NSLog(@"番号26");
    QCAR::TrackerManager& trackerManager = QCAR::TrackerManager::getInstance();
    QCAR::Tracker* tracker = trackerManager.getTracker(QCAR::ImageTracker::getClassType());
    if(tracker == 0) {
        NSLog(@"番号26a");
        return NO;
    }

    tracker->start();
    return YES;
}

// callback: the AR initialization is done
- (void) onInitARDone:(NSError *)initError {
    NSLog(@"番号27");
    //下記コード１行はインディケータのため
    [self hideLoadingAnimation];
    
    //プロジェクトにxml/dat形式でデータを追加すると、トラッカーとして判定されるようになった。
    //つまりトラッカー画像とコンテンツオブジェクトの結びつけはアプリ内で行われている（断定）
    if (initError == nil) {
        NSLog(@"番号27a");
        NSError * error = nil;
        [vapp startAR:QCAR::CameraDevice::CAMERA_BACK error:&error];
        
        // by default, we try to set the continuous auto focus mode
        // and we update menu to reflect the state of continuous auto-focus
        bool isContinuousAutofocus = QCAR::CameraDevice::getInstance().setFocusMode(QCAR::CameraDevice::FOCUS_MODE_CONTINUOUSAUTO);
        SampleAppMenu * menu = [SampleAppMenu instance];
        [menu setSelectionValueForCommand:C_AUTOFOCUS value:isContinuousAutofocus];
    } else {
        NSLog(@"番号27b");
        NSLog(@"Error initializing AR:%@", [initError description]);
    }
}


//データセットの切り替えを処理
- (void) onQCARUpdate: (QCAR::State *) state {
    NSLog(@"番号28");
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
}

// Load the image tracker data set
//DATとxmlファイルからデータセットファイルをロード
- (QCAR::DataSet *)loadImageTrackerDataSet:(NSString*)dataFile
{
    NSLog(@"番号29");
    NSLog(@"loadImageTrackerDataSet (%@)", dataFile);
    QCAR::DataSet * dataSet = NULL;
    
    //ここで取得完了？
    // Get the QCAR tracker manager image tracker
    QCAR::TrackerManager& trackerManager = QCAR::TrackerManager::getInstance();
    QCAR::ImageTracker* imageTracker = static_cast<QCAR::ImageTracker*>(trackerManager.getTracker(QCAR::ImageTracker::getClassType()));
    
    if (NULL == imageTracker) {
        
        NSLog(@"番号29a");
        NSLog(@"ERROR: failed to get the ImageTracker from the tracker manager");
        return NULL;
    } else {
        
        NSLog(@"番号29b");
        dataSet = imageTracker->createDataSet();
        
        if (NULL != dataSet) {
            NSLog(@"番号29ba");
            NSLog(@"INFO: successfully loaded data set");
            
            // Load the data set from the app's resources location
            if (!dataSet->load([dataFile cStringUsingEncoding:NSASCIIStringEncoding], QCAR::DataSet::STORAGE_APPRESOURCE)) {
                NSLog(@"番号29baa");
                NSLog(@"ERROR: failed to load data set");
                imageTracker->destroyDataSet(dataSet);
                dataSet = NULL;
            }
        }
        else {
            NSLog(@"番号29bb");
            NSLog(@"ERROR: failed to create data set");
        }
    }
    
    return dataSet;
}


- (bool) doStopTrackers {
    
    NSLog(@"番号30");
    // Stop the tracker
    QCAR::TrackerManager& trackerManager = QCAR::TrackerManager::getInstance();
    QCAR::Tracker* tracker = trackerManager.getTracker(QCAR::ImageTracker::getClassType());
    
    if (NULL != tracker) {
        
        NSLog(@"番号30a");
        tracker->stop();
        NSLog(@"INFO: successfully stopped tracker");
        return YES;
    }
    else {
        
        NSLog(@"番号30b");
        NSLog(@"ERROR: failed to get the tracker from the tracker manager");
        return NO;
    }
}

- (bool) doUnloadTrackersData {
    NSLog(@"番号31");
    [self deactivateDataSet: dataSetCurrent];
    dataSetCurrent = nil;
    return YES;
}


//データをアクティブに
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

//データをデアクティブに
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

//拡張追跡を開始または停止
- (BOOL) setExtendedTrackingForDataSet:(QCAR::DataSet *)theDataSet start:(BOOL) start {
    NSLog(@"番号37");
    BOOL result = YES;
    for (int tIdx = 0; tIdx < theDataSet->getNumTrackables(); tIdx++) {
        NSLog(@"番号37for");
        QCAR::Trackable* trackable = theDataSet->getTrackable(tIdx);
        if (start) {
            NSLog(@"番号37for/start");
            if (!trackable->startExtendedTracking())
            {
                NSLog(@"Failed to start extended tracking on: %s", trackable->getName());
                result = false;
            }
        } else {
            NSLog(@"番号37for/else");
            if (!trackable->stopExtendedTracking())
            {
                NSLog(@"Failed to stop extended tracking on: %s", trackable->getName());
                result = false;
            }
        }
    }
    return result;
}

- (bool) doDeinitTrackers {
    NSLog(@"番号38");
    QCAR::TrackerManager& trackerManager = QCAR::TrackerManager::getInstance();
    trackerManager.deinitTracker(QCAR::ImageTracker::getClassType());
    return YES;
}

- (void)autofocus:(UITapGestureRecognizer *)sender
{
    NSLog(@"番号39");
    [self performSelector:@selector(cameraPerformAutoFocus) withObject:nil afterDelay:.4];
}

- (void)cameraPerformAutoFocus
{
    NSLog(@"番号40");
    QCAR::CameraDevice::getInstance().setFocusMode(QCAR::CameraDevice::FOCUS_MODE_TRIGGERAUTO);
}


#pragma mark - left menu

typedef enum {
    C_EXTENDED_TRACKING,
    C_AUTOFOCUS,
    C_FLASH,
    C_CAMERA_FRONT,
    C_CAMERA_REAR,
    SWITCH_TO_TARMAC,
    SWITCH_TO_STONES_AND_CHIPS,
} MENU_COMMAND;

 //ここでコマンドをいじれる
- (void) prepareMenu {
    
    NSLog(@"番号41");
    //qualcom特有のコード群？///////////////
    SampleAppMenu * menu = [SampleAppMenu prepareWithCommandProtocol:self title:@"Image Targets"];
    SampleAppMenuGroup * group;
    
    group = [menu addGroup:@""];
    [group addTextItem:@"Vuforia Samples" command:-1];

    group = [menu addGroup:@""];
    [group addSelectionItem:@"Extended Tracking" command:C_EXTENDED_TRACKING isSelected:NO];
    [group addSelectionItem:@"Autofocus" command:C_AUTOFOCUS isSelected:NO];
    [group addSelectionItem:@"Flash" command:C_FLASH isSelected:NO];

    group = [menu addSelectionGroup:@"CAMERA"];
    [group addSelectionItem:@"Front" command:C_CAMERA_FRONT isSelected:NO];
    [group addSelectionItem:@"Rear" command:C_CAMERA_REAR isSelected:YES];

    group = [menu addSelectionGroup:@"DATABASE"];
    [group addSelectionItem:@"Stones & Chips" command:SWITCH_TO_STONES_AND_CHIPS isSelected:YES];
    [group addSelectionItem:@"Tarmac" command:SWITCH_TO_TARMAC isSelected:NO];
    //////////////////
}

- (bool) menuProcess:(SampleAppMenu *) menu command:(int) command value:(bool) value{
    bool result = true;
    NSError * error = nil;
    
    NSLog(@"番号42");
    switch(command) {
            NSLog(@"番号42switch");
        case C_FLASH:
            NSLog(@"番号42:case C_FLASH:");
            if (!QCAR::CameraDevice::getInstance().setFlashTorchMode(value)) {
                result = false;
            }
            break;
            
        case C_EXTENDED_TRACKING:
            NSLog(@"番号42:case C_EXTENDED_TRACKING:");
            result = [self setExtendedTrackingForDataSet:dataSetCurrent start:value];
            if (result) {
                [eaglView setOffTargetTrackingMode:value];
                extendedTrackingIsOn = value;
            }
            break;
            
        case C_CAMERA_FRONT:
            NSLog(@"番号42b:case C_CAMERA_FRONT:");
        case C_CAMERA_REAR: {
            NSLog(@"番号42b:case C_CAMERA_REAR:");
            if ([vapp stopCamera:&error]) {
                result = [vapp startAR:(command == C_CAMERA_FRONT) ? QCAR::CameraDevice::CAMERA_FRONT:QCAR::CameraDevice::CAMERA_BACK error:&error];
            } else {
                result = false;
            }
            if (result) {
                // if the camera switch worked, the flash will be off
                [menu setSelectionValueForCommand:C_FLASH value:false];
            }

        }
            break;
            
        case C_AUTOFOCUS:
        NSLog(@"番号42c:case C_AUTOFOCUS:");
        {
            int focusMode = value ? QCAR::CameraDevice::FOCUS_MODE_CONTINUOUSAUTO : QCAR::CameraDevice::FOCUS_MODE_NORMAL;
            result = QCAR::CameraDevice::getInstance().setFocusMode(focusMode);
        }
            break;
            
        case SWITCH_TO_TARMAC:
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
