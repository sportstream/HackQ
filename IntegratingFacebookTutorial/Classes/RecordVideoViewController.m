//
//  RecordVideoViewController.m
//  IntegratingFacebookTutorial
//
//  Created by Sid Mal on 10/21/14.
//
//

#import "RecordVideoViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <MediaPlayer/MediaPlayer.h>
#import "MBProgressHUD.h"

@interface RecordVideoViewController ()

@property NSURL *videoUrl;
@property MPMoviePlayerController *videoController;
@property MBProgressHUD *hud;
@property UIImagePickerController *cameraUI;
@property BOOL shootingVideo;
@property float recordTime;
@end

@implementation RecordVideoViewController

- (IBAction)redoTap
{
    [self showCamera];
}

- (IBAction)saveTap
{
    self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [self.hud setLabelText:@"Sending"];
    [self.hud setDimBackground:YES];
    PFFile *videoFile = [PFFile fileWithData:[NSData dataWithContentsOfURL:self.videoUrl]];
    [videoFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            PFObject *video = [PFObject objectWithClassName:@"Video"];
            video[@"videoFile"] = videoFile;
            [video setObject:[PFUser currentUser] forKey:@"user"];
            [video saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (succeeded) {
                    // update activity table
                    PFObject *activityItem = [PFObject objectWithClassName:@"Activity"];
                    [activityItem setObject:[PFUser currentUser] forKey:@"fromUser"];
                    [activityItem setObject:self.toUser forKey:@"toUser"];
                    // TODO
                    //[activityItem setObject:nil forKey:@"toUser"];
                    [activityItem setObject:video forKey:@"video"];
                    [activityItem setObject:@"question" forKey:@"type"];
                    [activityItem setObject:@"video_question" forKey:@"content"];
                    [activityItem saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                        if (succeeded) {
                            [self.hud setLabelText:@"Sent!"];
                            
                            self.hud.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkmark.png"]];
                            
                            // Set custom view mode
                            self.hud.mode = MBProgressHUDModeCustomView;
                            [self.hud hide:YES afterDelay:3];
                        }
                    }];
                }
            }];
        }
        else
            [MBProgressHUD hideHUDForView:self.view animated:YES];
    }];
}

-(IBAction)playTap
{
    _videoController = [[MPMoviePlayerController alloc] init];
    [self.videoController setContentURL:self.videoUrl];
    [self.videoController.view setFrame:self.imageView.frame];
//    [self.videoController.view setFrame:[[UIScreen mainScreen] bounds]];
//    [self.videoController setFullscreen:YES];
    self.videoController.scalingMode = MPMovieScalingModeAspectFit;
    self.videoController.controlStyle = MPMovieControlStyleNone;
    [self.view addSubview:self.videoController.view];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(videoPlayBackDidFinish:)
                                                 name:MPMoviePlayerPlaybackDidFinishNotification
                                               object:self.videoController];
    [self.videoController play];
//    [self.view bringSubviewToFront:self.videoView];
}

-(IBAction)xTap
{
    [self showTabBar:self.tabBarController];
    [self.navigationController popViewControllerAnimated:NO];
}


- (void)videoPlayBackDidFinish:(NSNotification *)notification
{
    self.obscureView.hidden = YES;
    [[NSNotificationCenter defaultCenter]removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
    // Stop the video player and remove it from view
    [self.videoController stop];
    [self.videoController.view removeFromSuperview];
    self.videoController = nil;
}


-(void)showCamera
{
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] == NO) {
        return;
    }
    
    _cameraUI = [[UIImagePickerController alloc] init];
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]
        && [[UIImagePickerController availableMediaTypesForSourceType:
             UIImagePickerControllerSourceTypeCamera] containsObject:(NSString *)kUTTypeMovie]) {
        
        _cameraUI.mediaTypes = [NSArray arrayWithObject:(NSString *) kUTTypeMovie];
        _cameraUI.sourceType = UIImagePickerControllerSourceTypeCamera;
        
        if ([UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront]) {
            _cameraUI.cameraDevice = UIImagePickerControllerCameraDeviceFront;
        } else if ([UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear]) {
            _cameraUI.cameraDevice = UIImagePickerControllerCameraDeviceRear;
        }
        
    } else {
        return;
    }
    
    
    // create the overlay view
    UIView *overlayView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    
    // important - it needs to be transparent so the camera preview shows through!
    overlayView.opaque=NO;
    overlayView.backgroundColor=[UIColor clearColor];
    
    int recordButtonSize = 75;
    UIButton *recordButton = [UIButton buttonWithType:UIButtonTypeCustom];
    recordButton.frame = CGRectMake((self.view.frame.size.width-recordButtonSize)/2,self.view.frame.size.height-recordButtonSize-10,recordButtonSize,recordButtonSize);
    [recordButton setImage:[UIImage imageNamed:@"redButton"] forState:UIControlStateNormal];
    [recordButton addTarget:self action:@selector(shootVideo:) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    backButton.frame = CGRectMake(10,20,30,30);
    [backButton setImage:[UIImage imageNamed:@"leftArrowWhite"] forState:UIControlStateNormal];
    [backButton addTarget:self action:@selector(backButtonTap:) forControlEvents:UIControlEventTouchUpInside];

    int timeLabelWidth = 50;
    UILabel *timeLabel = [UILabel new];
    timeLabel.frame = CGRectMake(self.view.frame.size.width-timeLabelWidth-10,20,timeLabelWidth,30);
    timeLabel.textColor = [UIColor whiteColor];
    timeLabel.text = @"0";
    
    // parent view for our overlay
    UIView *cameraView=[[UIView alloc] initWithFrame:self.view.bounds];
    [cameraView addSubview:overlayView];
    [cameraView addSubview:recordButton];
    [cameraView addSubview:backButton];
    [cameraView addSubview:timeLabel];
    
    [_cameraUI setCameraOverlayView:cameraView];
    
    _cameraUI.allowsEditing = NO;
    _cameraUI.showsCameraControls = NO;
    _cameraUI.delegate = self;
    
    [self presentViewController:_cameraUI animated:YES completion:nil];
}

-(void)backButtonTap:(id)sender
{
    self.navigationController.navigationBarHidden = NO;
    [self dismissViewControllerAnimated:YES completion:nil];
    [self.navigationController popToRootViewControllerAnimated:NO];
}

-(void) shootVideo:(id)sender
{
    UIButton *recordButton = (UIButton *)sender;
    if (self.shootingVideo == YES)
    {
        self.shootingVideo = NO;
        [_cameraUI stopVideoCapture];
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [recordButton setHighlighted:NO];
        }];
    }
    else
    {
        self.shootingVideo = YES;
        [_cameraUI startVideoCapture];
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [recordButton setHighlighted:YES];
        }];
    }
}

- (void)cancelPicture {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.obscureView.hidden = NO;
    [self showCamera];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UIImagePickerDelegate

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [self hideTabBar:self.tabBarController];
    [self dismissViewControllerAnimated:YES completion:nil];
    
    MPMoviePlayerController *theMovie = [[MPMoviePlayerController alloc] initWithContentURL:[info objectForKey:@"UIImagePickerControllerMediaURL"]];
    theMovie.view.frame = self.imageView.frame;
    theMovie.controlStyle = MPMovieControlStyleNone;
    theMovie.shouldAutoplay=NO;
    theMovie.scalingMode = MPMovieScalingModeAspectFit;
    self.imageView.image = [theMovie thumbnailImageAtTime:0 timeOption:MPMovieTimeOptionExact];
    self.videoUrl = [info objectForKey:@"UIImagePickerControllerMediaURL"];
    [self playTap];
}

- (void) hideTabBar:(UITabBarController *) tabbarcontroller
{
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.5];
    float fHeight = screenRect.size.height;
    if(  UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation) )
    {
        fHeight = screenRect.size.width;
    }
    
    for(UIView *view in tabbarcontroller.view.subviews)
    {
        if([view isKindOfClass:[UITabBar class]])
        {
            [view setFrame:CGRectMake(view.frame.origin.x, fHeight, view.frame.size.width, view.frame.size.height)];
        }
        else
        {
            [view setFrame:CGRectMake(view.frame.origin.x, view.frame.origin.y, view.frame.size.width, fHeight)];
            view.backgroundColor = [UIColor blackColor];
        }
    }
    [UIView commitAnimations];
}


- (void) showTabBar:(UITabBarController *) tabbarcontroller
{
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    float fHeight = screenRect.size.height - tabbarcontroller.tabBar.frame.size.height;
    
    if(  UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation) )
    {
        fHeight = screenRect.size.width - tabbarcontroller.tabBar.frame.size.height;
    }
    
    for(UIView *view in tabbarcontroller.view.subviews)
    {
        if([view isKindOfClass:[UITabBar class]])
        {
            [view setFrame:CGRectMake(view.frame.origin.x, fHeight, view.frame.size.width, view.frame.size.height)];
        }
        else
        {
            [view setFrame:CGRectMake(view.frame.origin.x, view.frame.origin.y, view.frame.size.width, fHeight)];
        }
    }
}

@end
