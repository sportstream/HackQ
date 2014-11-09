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
#import "NotificationHelper.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "HackVideoPlayer.h"
#import "AppDelegate.h"

@interface RecordVideoViewController ()

@property NSURL *videoUrl;
@property UIImage *thumbnailImg;
@property MPMoviePlayerController *videoController;
@property MBProgressHUD *hud;
@property UIImagePickerController *cameraUI;
@property BOOL shootingVideo;
@property float recordTime;
@property RecordViewMode mode;
@property __block PFActivityObject *activityObject;
@property NSTimer *timeTimer;
@property UILabel *timeLabel;
@property NSURL *questionVideoUrl;
@property __block NSURL *concatVideoURL;
@end

typedef void (^VideosUploadedBooleanResultBlock)(PFObject *video, PFObject *concatVideo);

@implementation RecordVideoViewController

- (id)initWithMode:(RecordViewMode)mode withRecipient:(PFUser *)toUser {
    if (self = [super initWithNibName:@"RecordVideoViewController" bundle:nil]) {
        // Initialization code
        self.mode = mode;
        self.toUser = toUser;
    }
    return self;
}

- (id)initWithMode:(RecordViewMode)mode withRecipient:(PFUser *)toUser withActivityObject:(PFActivityObject *)activityObject withQuestionVideoUrl:(NSURL *)questionVideoUrl {
    if (self = [self initWithMode:mode withRecipient:toUser]) {
        // Initialization code
        self.questionVideoUrl = questionVideoUrl;
        self.activityObject = activityObject;
    }
    return self;
}

- (PFActivityObject*)initializeActivityClassItem {
    PFObject *video;
    
    PFActivityObject *activityItem = [PFActivityObject object];
    [activityItem setObject:[PFUser currentUser] forKey:@"fromUser"];
    [activityItem setObject:self.toUser forKey:@"toUser"];
    
    [activityItem setObject:[NSNumber numberWithBool:NO] forKey:@"replied"];
    [activityItem setObject:[NSNumber numberWithBool:NO] forKey:@"seen"];
    switch (self.mode) {
        case RecordViewModeQuestion:
            [activityItem setObject:@"question" forKey:@"type"];
            [activityItem setObject:@"video_question" forKey:@"content"];
            break;
        case RecordViewModeAnswer:
            video = [[self activityObject] objectForKey:@"video"];
            [activityItem setObject:video forKey:@"answerTo"];
            [activityItem setObject:@"answer" forKey:@"type"];
            [activityItem setObject:@"video_answer" forKey:@"content"];
            break;
        default:
            break;
    }
    return activityItem;
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

    UIView *overlayView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 50)];
    overlayView.backgroundColor=[UIColor blackColor];
    overlayView.alpha = 0.7;
    
    int recordButtonSize = 75;
    UIButton *recordButton = [UIButton buttonWithType:UIButtonTypeCustom];
    recordButton.frame = CGRectMake((self.view.frame.size.width-recordButtonSize)/2,self.view.frame.size.height-recordButtonSize-10,recordButtonSize,recordButtonSize);
    [recordButton setImage:[UIImage imageNamed:@"redButton"] forState:UIControlStateNormal];
    [recordButton addTarget:self action:@selector(shootVideo:) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    backButton.frame = CGRectMake(10,15,25,25);
    [[backButton imageView] setContentMode: UIViewContentModeScaleAspectFit];

    [backButton setImage:[UIImage imageNamed:@"chevronLeft"] forState:UIControlStateNormal];
    [backButton addTarget:self action:@selector(backButtonTap:) forControlEvents:UIControlEventTouchUpInside];

    int timeLabelWidth = 35;
    _timeLabel = [UILabel new];
    self.timeLabel.frame = CGRectMake(self.view.frame.size.width-timeLabelWidth-10,15,timeLabelWidth,30);
    self.timeLabel.textColor = [UIColor whiteColor];
    self.timeLabel.text = @"0.0";
    
    // parent view for our overlay
    UIView *cameraView=[[UIView alloc] initWithFrame:self.view.bounds];
    [cameraView addSubview:overlayView];
    [cameraView addSubview:recordButton];
    [cameraView addSubview:backButton];
    [cameraView addSubview:_timeLabel];
    
    [_cameraUI setCameraOverlayView:cameraView];
    
    _cameraUI.allowsEditing = NO;
    _cameraUI.showsCameraControls = NO;
    _cameraUI.delegate = self;
    
    [self presentViewController:_cameraUI animated:YES completion:nil];
}

#pragma mark - shoot video buttons

-(void)backButtonTap:(id)sender
{
    self.navigationController.navigationBarHidden = NO;
    [self dismissViewControllerAnimated:YES completion:nil];
    [self.navigationController popToRootViewControllerAnimated:NO];
}

-(void)shootVideo:(id)sender
{
    UIButton *recordButton = (UIButton *)sender;
    if (self.shootingVideo == YES)
    {
        if (self.timeTimer != nil)
        {
            [self.timeTimer invalidate];
            self.timeTimer = nil;
        }
        self.shootingVideo = NO;
        [_cameraUI stopVideoCapture];
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [recordButton setHighlighted:NO];
        }];
    }
    else
    {
        self.timeTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(timeTimerFired) userInfo:nil repeats:YES];
        self.shootingVideo = YES;
        [_cameraUI startVideoCapture];
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [recordButton setHighlighted:YES];
        }];
    }
}

-(IBAction)xTap
{
    self.navigationController.navigationBarHidden = NO;
    [(AppDelegate *)[[UIApplication sharedApplication] delegate] showTabBar:self.tabBarController];
    [self.navigationController popViewControllerAnimated:NO];
}

-(void)timeTimerFired
{
    _recordTime += .1;
    _timeLabel.text = [NSString stringWithFormat:@"%.1f",floorf(_recordTime)];
}

#pragma mark - review video buttons

- (IBAction)redoTap
{
    _recordTime = 0.0;
    [self showCamera];
}

-(void)updateOriginalActivityItem:(PFObject *)concatVideo {
    // original video activity object's property replied value should be updated to TRUE.
    [self.activityObject updateRepliedValue:[NSNumber numberWithBool:YES]];
    
    // original video activity object's property stitchedVideo value should be updated accordingly.
    [self.activityObject updateValue:concatVideo withKey:@"stitchedVideo"];

}

- (IBAction)saveTap
{
    self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [self.hud setLabelText:@"Sending"];
    [self.hud setDimBackground:YES];
    
    PFFile *thumbnailFile = [PFFile fileWithData:UIImageJPEGRepresentation(self.thumbnailImg, 0.8)];
    [thumbnailFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        // upload new recorded video
        PFFile *videoFile = [PFFile fileWithData:[NSData dataWithContentsOfURL:self.videoUrl]];
        [videoFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (succeeded) {
                PFObject *video = [PFObject objectWithClassName:@"Video"];
                video[@"videoFile"] = videoFile;
                [video setObject:[PFUser currentUser] forKey:@"user"];
                [video saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                    
                    VideosUploadedBooleanResultBlock callbackBlock = ^(PFObject *video, PFObject *concatVideo) {
                        // prepare activity class object
                        PFActivityObject *activityItem = [self initializeActivityClassItem];
                        [activityItem setObject:video forKey:@"video"];
                        [activityItem setObject:thumbnailFile forKey:@"thumbnailFile"];
                        if (concatVideo != nil)
                        [activityItem setObject:concatVideo forKey:@"stitchedVideo"];
                        
                        // update activity table
                        [activityItem saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                            if (succeeded) {
                                [self.hud setLabelText:@"Replied!"];
                                
                                self.hud.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkmark.png"]];
                                
                                // Set custom view mode
                                self.hud.mode = MBProgressHUDModeCustomView;
                                [self.hud hide:YES afterDelay:3];
                                
                                if (self.mode == RecordViewModeAnswer) {
                                    
                                    // update original activity item(question)
                                    [self updateOriginalActivityItem:concatVideo];
                                    
                                    // TODO
                                    // for some reason self.activityObject hasn't been updated at this point
                                    // and HackVideoPlayer plays the original question video.
                                    // will fix it.
                                    //[self loadVideoPlayer:self.concatVideoURL];
                                    
                                    //HACK
                                    NSDictionary *userInfo = @{
                                                               @"url" : self.concatVideoURL
                                                               };
                                    [NotificationHelper pushNotification:NotificationQuestionVideoURLUpdated WithObject:userInfo];
                                }
                                [self xTap];
                            }
                        }];
                    };
                    
                    if (succeeded) {
                        if (self.mode == RecordViewModeAnswer) {
                            // concat two videos and
                            // upload concatinated video
                            [self videoConcat:^(NSURL *concatVideoUrl) {
                                // save the reference
                                self.concatVideoURL = concatVideoUrl;
                                
                                // upload the video
                                PFFile *concatVideoFile = [PFFile fileWithData:[NSData dataWithContentsOfURL:concatVideoUrl]];
                                [concatVideoFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                                    if (succeeded) {
                                        PFObject *concatVideo = [PFObject objectWithClassName:@"Video"];
                                        concatVideo[@"videoFile"] = concatVideoFile;
                                        [concatVideo saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                                            if (succeeded) {
                                                dispatch_async(dispatch_get_main_queue(), ^{
                                                    callbackBlock(video, concatVideo);
                                                });
                                            }
                                        }];
                                    }
                                }];
                                
                            }];
                            
                        }
                        else if (self.mode == RecordViewModeQuestion) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                callbackBlock(video, nil);
                            });
                        }
                        
                    }
                }];
            }
            else
            [MBProgressHUD hideHUDForView:self.view animated:YES];
        }];
    }];
    

}

-(IBAction)playTap
{
    [self playVideo:self.videoUrl];
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

#pragma mark - UIImagePickerDelegate

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [(AppDelegate *)[[UIApplication sharedApplication] delegate] hideTabBar:self.tabBarController];
    [self dismissViewControllerAnimated:YES completion:nil];
    
    MPMoviePlayerController *theMovie = [[MPMoviePlayerController alloc] initWithContentURL:[info objectForKey:@"UIImagePickerControllerMediaURL"]];
    theMovie.view.frame = self.imageView.frame;
    theMovie.controlStyle = MPMovieControlStyleNone;
    theMovie.shouldAutoplay=NO;
    theMovie.scalingMode = MPMovieScalingModeAspectFit;
    self.thumbnailImg = [theMovie thumbnailImageAtTime:0 timeOption:MPMovieTimeOptionExact];
    self.imageView.image = _thumbnailImg;
    self.videoUrl = [info objectForKey:@"UIImagePickerControllerMediaURL"];
    
    //for autoplay uncomment this and remove self.obscureView.hidden = YES;
//    [self playTap];
    self.obscureView.hidden = YES;
}

#pragma mark -
-(void)videoConcat:(void (^) (NSURL *concatVideoUrl)) block
{
    AVURLAsset *question = [AVURLAsset URLAssetWithURL:self.questionVideoUrl options:nil];
    AVURLAsset *answer = [AVURLAsset URLAssetWithURL:self.videoUrl options:nil];
    
    AVMutableComposition* mixComposition = [[AVMutableComposition alloc] init];
    AVMutableCompositionTrack *firstTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    AVMutableCompositionTrack *firstTrackAudio = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio
                                                                             preferredTrackID:kCMPersistentTrackID_Invalid];
    firstTrack.preferredTransform = CGAffineTransformMakeRotation(M_PI/2);
    
    [firstTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, question.duration) ofTrack:[[question tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] atTime:kCMTimeZero error:nil];
    [firstTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, answer.duration) ofTrack:[[answer tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] atTime:question.duration error:nil];

    if ([[question tracksWithMediaType:AVMediaTypeAudio] count] > 0)
    {
        AVAssetTrack *clipAudioTrack = [[question tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
        [firstTrackAudio insertTimeRange:CMTimeRangeMake(kCMTimeZero, question.duration) ofTrack:clipAudioTrack atTime:kCMTimeZero error:nil];
    }
    
    if ([[answer tracksWithMediaType:AVMediaTypeAudio] count] > 0)
    {
        AVAssetTrack *clipAudioTrack = [[answer tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
        [firstTrackAudio insertTimeRange:CMTimeRangeMake(kCMTimeZero, answer.duration) ofTrack:clipAudioTrack atTime:question.duration error:nil];
    }
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *myPathDocs =  [documentsDirectory stringByAppendingPathComponent:
                             [NSString stringWithFormat:@"mergeVideo-%d.mov",arc4random() % 1000]];
    NSURL *url = [NSURL fileURLWithPath:myPathDocs];
    // 5 - Create exporter
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:mixComposition
                                                                      presetName:AVAssetExportPresetHighestQuality];
    exporter.outputURL=url;
    exporter.outputFileType = AVFileTypeQuickTimeMovie;
    exporter.shouldOptimizeForNetworkUse = YES;
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
//            [self exportDidFinish:exporter];
            block(exporter.outputURL);
        });
    }];
}

-(void)exportDidFinish:(AVAssetExportSession*)session
{
    if (session.status == AVAssetExportSessionStatusCompleted) {
        NSURL *outputURL = session.outputURL;
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        if ([library videoAtPathIsCompatibleWithSavedPhotosAlbum:outputURL]) {
            [library writeVideoAtPathToSavedPhotosAlbum:outputURL completionBlock:^(NSURL *assetURL, NSError *error){
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (error) {
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Video Saving Failed"
                                                                       delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                        [alert show];
                    } else {
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Video Saved" message:@"Saved To Photo Album"
                                                                       delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                        [alert show];
                    }
                });
            }];
        }
    }
}

-(void)loadVideoPlayer:(NSURL *)videoURL {
    HackVideoPlayer *videoPlayer = [[HackVideoPlayer alloc] initWithContentURL:videoURL];
    if (self.activityObject != nil)
        videoPlayer.activityItem = self.activityObject;
    
    [self.navigationController pushViewController:videoPlayer animated:YES];
}

#pragma mark - play video

-(void)playVideo:(NSURL *)url
{
    _videoController = [[MPMoviePlayerController alloc] init];
    [self.videoController setContentURL:url];
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

}

#pragma mark -

- (void)viewDidLoad {
    [super viewDidLoad];
    self.obscureView.hidden = NO;
    [self showCamera];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
