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
@end


@implementation RecordVideoViewController

- (IBAction)redoTap
{
    [self showCamera];
}

- (IBAction)saveTap
{
    self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [self.hud setLabelText:@"Saving"];
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
                    // TODO
                    //[activityItem setObject:nil forKey:@"toUser"];
                    [activityItem setObject:video forKey:@"video"];
                    [activityItem setObject:@"question" forKey:@"type"];
                    [activityItem setObject:@"video_question" forKey:@"content"];
                    [activityItem saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                        if (succeeded) {
                            [self.hud setLabelText:@"Saved!"];
                            
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

- (void)videoPlayBackDidFinish:(NSNotification *)notification
{
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
    
    UIButton *recordButton = [UIButton buttonWithType:UIButtonTypeCustom];
    recordButton.frame = CGRectMake((self.view.frame.size.width-100)/2,self.view.frame.size.height-110,100,100);
    [recordButton setImage:[UIImage imageNamed:@"recordVideoIcon"] forState:UIControlStateNormal];
    [recordButton addTarget:self action:@selector(shootVideo:) forControlEvents:UIControlEventTouchUpInside];
    
    // parent view for our overlay
    UIView *cameraView=[[UIView alloc] initWithFrame:self.view.bounds];
    [cameraView addSubview:overlayView];
    [cameraView addSubview:recordButton];
    
    [_cameraUI setCameraOverlayView:cameraView];
    
    _cameraUI.allowsEditing = NO;
    _cameraUI.showsCameraControls = NO;
    _cameraUI.delegate = self;
    
    [self presentViewController:_cameraUI animated:YES completion:nil];
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
    [self dismissViewControllerAnimated:YES completion:nil];
    
    MPMoviePlayerController *theMovie = [[MPMoviePlayerController alloc] initWithContentURL:[info objectForKey:@"UIImagePickerControllerMediaURL"]];
    theMovie.view.frame = self.imageView.frame;
    theMovie.controlStyle = MPMovieControlStyleNone;
    theMovie.shouldAutoplay=NO;
    theMovie.scalingMode = MPMovieScalingModeAspectFit;
    self.imageView.image = [theMovie thumbnailImageAtTime:0 timeOption:MPMovieTimeOptionExact];
    self.videoUrl = [info objectForKey:@"UIImagePickerControllerMediaURL"];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
