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
            [video saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                [self.hud setLabelText:@"Saved!"];

                self.hud.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkmark.png"]];
                
                // Set custom view mode
                self.hud.mode = MBProgressHUDModeCustomView;
                [self.hud hide:YES afterDelay:3];
                
            }];
        }
        else
            [MBProgressHUD hideHUDForView:self.view animated:YES];
    }];
}

-(IBAction)playTap
{
    self.videoController = [[MPMoviePlayerController alloc] init];
    
    [self.videoController setContentURL:self.videoUrl];
    [self.videoController.view setFrame:self.view.frame];
    self.videoController.controlStyle = MPMovieControlStyleDefault;
    [self.view addSubview:self.videoController.view];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(videoPlayBackDidFinish:)
                                                 name:MPMoviePlayerPlaybackDidFinishNotification
                                               object:self.videoController];
    [self.videoController play];
}

- (void)videoPlayBackDidFinish:(NSNotification *)notification {
    
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
    
    UIImagePickerController *cameraUI = [[UIImagePickerController alloc] init];
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]
        && [[UIImagePickerController availableMediaTypesForSourceType:
             UIImagePickerControllerSourceTypeCamera] containsObject:(NSString *)kUTTypeMovie]) {
        
        cameraUI.mediaTypes = [NSArray arrayWithObject:(NSString *) kUTTypeMovie];
        cameraUI.sourceType = UIImagePickerControllerSourceTypeCamera;
        
        if ([UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront]) {
            cameraUI.cameraDevice = UIImagePickerControllerCameraDeviceFront;
        } else if ([UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear]) {
            cameraUI.cameraDevice = UIImagePickerControllerCameraDeviceRear;
        }
        
    } else {
        return;
    }
    
    cameraUI.allowsEditing = YES;
    cameraUI.showsCameraControls = YES;
    cameraUI.delegate = self;
    
    [self presentViewController:cameraUI animated:YES completion:nil];
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
    theMovie.view.frame = self.view.bounds;
    theMovie.controlStyle = MPMovieControlStyleNone;
    theMovie.shouldAutoplay=NO;

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
