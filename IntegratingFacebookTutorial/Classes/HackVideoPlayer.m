//
//  HackVideoPlayer.m
//  IntegratingFacebookTutorial
//
//  Created by Sirri Perek on 11/1/14.
//
//

#import "HackVideoPlayer.h"
#import "RecordVideoViewController.h"
#import "AppDelegate.h"
#import "NotificationHelper.h"
#import "MBProgressHUD.h"

@interface HackVideoPlayer ()

@property UIButton *playButton;
@property UIButton *replyButton;
@property UIButton *shareButton;
@property NSURL *currentVideoURL;
@property MBProgressHUD *hud;

@end

@implementation HackVideoPlayer

- (id)initWithData:(NSData *)data {
    if (self = [self initWithContentURL:[self getVideoURLWithData:data]]) {
        // Initialization code
    }
    return self;
}

- (instancetype)initWithContentURL:(NSURL *)url {
    if (self = [super initWithContentURL:url]) {
        self.currentVideoURL = url;
        
        // register for notification
        [NotificationHelper registerForNotification:NotificationQuestionVideoURLUpdated WithDelegate:self];
    }
    return self;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.barTintColor = [UIColor blackColor];
    [(AppDelegate *)[[UIApplication sharedApplication] delegate] hideTabBar:self.tabBarController];
    
    // hide it by default until user finishes watching the video.
    [self hideReplyButton];
    [self hideShareButton];
    
    // react on any updates on currentVideoURL
    MPMoviePlayerController *videoController = [self moviePlayer];
    if (![self.currentVideoURL isEqual:[videoController contentURL]]) {
        [videoController setContentURL:self.currentVideoURL];
        [videoController prepareToPlay];
    }
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self playAction:nil]; //autoplay 
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [(AppDelegate *)[[UIApplication sharedApplication] delegate] showTabBar:self.tabBarController];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.playButton = [self createPlayButton];
    self.replyButton = [self createReplyButton];
    self.shareButton = [self createShareButton];
    
    [self.view addSubview:self.playButton];
    [self.view addSubview:self.replyButton];
    [self.view addSubview:self.shareButton];
    
    MPMoviePlayerController *videoController = [self moviePlayer];
    videoController.fullscreen = YES;
    videoController.shouldAutoplay = NO;
    videoController.scalingMode = MPMovieScalingModeAspectFit;
    videoController.controlStyle = MPMovieControlStyleNone;
}

- (NSURL *)getVideoURLWithData:(NSData *)data {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *appFile = [documentsDirectory stringByAppendingPathComponent:@"MyFile.mov"];
    [data writeToFile:appFile atomically:YES];
    //and then into NSURL.
    return [NSURL fileURLWithPath:appFile];
}

- (UIButton *)createPlayButton {    // Method for creating button, with background image and other properties
    UIButton *playButton = [UIButton buttonWithType:UIButtonTypeCustom];
    playButton.frame = CGRectMake(110.0, 360.0, 100.0, 100.0);
    UIImage *buttonImageNormal = [UIImage imageNamed:@"playIcon.png"];
    playButton.backgroundColor = [UIColor clearColor];
    [playButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal ];
    [playButton setBackgroundImage:buttonImageNormal forState:UIControlStateNormal];
    [playButton addTarget:self action:@selector(playAction:) forControlEvents:UIControlEventTouchUpInside];
    return playButton;
}

- (UIButton *)createReplyButton {    // Method for creating button, with background image and other properties
    UIButton *replyButton = [UIButton buttonWithType:UIButtonTypeCustom];
    replyButton.frame = CGRectMake(110.0, 200.0, 100.0, 40.0);
    [replyButton setTitle:@"Reply" forState:UIControlStateNormal];
    replyButton.backgroundColor = [UIColor grayColor];
    [replyButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [replyButton addTarget:self action:@selector(replyAction:) forControlEvents:UIControlEventTouchUpInside];
    return replyButton;
}

- (UIButton *)createShareButton {    // Method for creating button, with background image and other properties
    UIButton *shareButton = [UIButton buttonWithType:UIButtonTypeCustom];
    shareButton.frame = CGRectMake(90.0, 250.0, 140.0, 40.0);
    [shareButton setTitle:@"Share on FB" forState:UIControlStateNormal];
    shareButton.backgroundColor = [UIColor grayColor];
    [shareButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [shareButton addTarget:self action:@selector(shareAction:) forControlEvents:UIControlEventTouchUpInside];
    return shareButton;
}

- (void)shareAction:(id)sender {
    self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [self.hud setLabelText:@"Uploading"];
    [self.hud setDimBackground:YES];
    [(AppDelegate *)[[UIApplication sharedApplication] delegate] postVideoToFacebook:[NSData dataWithContentsOfURL:self.currentVideoURL] withCallback:^(BOOL succeed) {
        if (succeed) {
            [self.hud setLabelText:@"Shared!"];
            
            self.hud.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkmark.png"]];
            
            // Set custom view mode
            self.hud.mode = MBProgressHUDModeCustomView;
            [self.hud hide:YES afterDelay:1];
        }
        else {
            [self.hud setLabelText:@"Error! Try again"];
            // Set custom view mode
            self.hud.mode = MBProgressHUDModeCustomView;
            [self.hud hide:YES afterDelay:3];
        }
    }];
}

- (void)replyAction:(id)sender {
    if ([self.activityItem hasBeenRepliedBefore]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Problem"
                                                        message:@"You answered this question already!"
                                                       delegate:nil
                                              cancelButtonTitle:nil
                                              otherButtonTitles:@"OK", nil];
        [alert show];
        return;
    }
    PFUser *toUser = (PFUser *)[self.activityItem objectForKey:@"fromUser"];
    RecordVideoViewController *r = [[RecordVideoViewController alloc] initWithMode:RecordViewModeAnswer withRecipient:toUser withActivityObject:self.activityItem withQuestionVideoUrl:self.currentVideoURL];
    self.navigationController.navigationBarHidden = YES;
    [self.navigationController pushViewController:r animated:YES];
}

- (void)playAction:(id)sender {
    [self hidePlayButton];
    [self hideReplyButton];
    [self hideShareButton];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(videoPlayBackDidFinish:)
                                                 name:MPMoviePlayerPlaybackDidFinishNotification
                                               object:self.moviePlayer];
    [self.moviePlayer play];
    
    // update seen value
    [self.activityItem updateSeenValue:[NSNumber numberWithBool:YES]];
}

- (void)videoPlayBackDidFinish:(NSNotification *)notification
{
    [self showPlayButton];
    
    if ([self.activityItem canVideoBeShared])
        [self showShareButton];
    
    if ([self.activityItem canVideoBeReplied])
        [self showReplyButton];
    
    [[NSNotificationCenter defaultCenter]removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
    // Stop the video player and remove it from view
//    [self.moviePlayer stop];
    //[self.videoViewController dismissMoviePlayerViewControllerAnimated];
    //[self.navigationController popViewControllerAnimated:YES];
}

- (void)reactOnNotification:(NSNotification*)notification {
    NSDictionary *userInfo = [notification object];
    NSURL *url = [userInfo objectForKey:@"url"];
    if (url)
        self.currentVideoURL = url;
}

- (void)showPlayButton {
    [self.playButton setHidden:NO];
}

- (void)hidePlayButton {
    [self.playButton setHidden:YES];
}

- (void)showReplyButton {
    [self.replyButton setHidden:NO];
}

- (void)hideReplyButton {
    [self.replyButton setHidden:YES];
}

- (void)showShareButton {
    [self.shareButton setHidden:NO];
}

- (void)hideShareButton {
    [self.shareButton setHidden:YES];
}

@end
