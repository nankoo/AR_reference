/*==============================================================================
 Copyright (c) 2012-2013 Qualcomm Connected Experiences, Inc.
 All Rights Reserved.
 ==============================================================================*/



#import "SampleAppSelectorViewController.h"
#import "SampleAppAboutViewController.h"
#import "SampleAppMenu.h"

@interface SampleApplicationInfo : NSObject
@property (nonatomic, copy) NSString * title;
@property (nonatomic, copy) NSString * aboutPageName;
@property (nonatomic, copy) NSString * viewControllerClassName;
@end

@implementation SampleApplicationInfo
@end


@interface SampleAppSelectorViewController ()
@property (retain) NSMutableArray * sampleApplications;
@end

@implementation SampleAppSelectorViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.title = @"Vuforia Samples";
        self.sampleApplications = [NSMutableArray arrayWithCapacity:12];
        [self addApplication:@"Image Targets" viewControllerClassName:@"ImageTargetsViewController" aboutPageName:@"IT_about"];

        //[self addApplication:@"VideoPlayback" viewControllerClassName:@"VideoPlaybackViewController" aboutPageName:@"VP_about"];

    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) addApplication:(NSString *)title viewControllerClassName:(NSString *) viewControllerClassName aboutPageName:(NSString *)aboutPageName{
    SampleApplicationInfo * app = [[[SampleApplicationInfo alloc]init] autorelease];
    app.title = title;
    app.viewControllerClassName = viewControllerClassName;
    app.aboutPageName = aboutPageName;
    [self.sampleApplications addObject:app];
}


//------------------------------------------------------------------------------
#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    SampleApplicationInfo * application = [self.sampleApplications objectAtIndex:indexPath.row];
    
    if (application.viewControllerClassName != nil) {
        // change the back button
        self.navigationItem.backBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Back" style: UIBarButtonItemStyleBordered target:nil action:nil] autorelease];
        
        // cleanup menu in case the sample app doesn't not set menu items
        [[SampleAppMenu instance]clear];
        
        SampleAppAboutViewController *vc = [[[SampleAppAboutViewController alloc] initWithNibName:@"SampleAppAboutViewController" bundle:nil] autorelease];
        vc.appTitle = application.title;
        vc.appAboutPageName = application.aboutPageName;
        vc.appViewControllerClassName = application.viewControllerClassName;

        [self.navigationController pushViewController:vc animated:YES];
    }
}


#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.sampleApplications count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"SampleAppSelectorViewControllerCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
    }
    
    // Configure the cell...
    SampleApplicationInfo * application = [self.sampleApplications objectAtIndex:indexPath.row];
    
    cell.textLabel.text = application.title;
    
    if (application.viewControllerClassName != nil) {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else {
        cell.accessoryType = UITableViewCellSelectionStyleNone;
    }
    
    return cell;
}
@end
