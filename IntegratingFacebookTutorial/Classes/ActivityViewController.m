//
//  ActivityViewController.m
//  IntegratingFacebookTutorial
//
//  Created by Sirri Perek on 10/27/14.
//
//

#import "ActivityViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <MediaPlayer/MediaPlayer.h>
#import "MBProgressHUD.h"
#import "RecordVideoViewController.h"

@interface ActivityViewController ()

@property MPMoviePlayerViewController *videoViewController;
@property UIButton *playButton;
@property UIButton *replyButton;
@property PFObject *selectedActivityItem;
@property NSURL *currentVideoUrl;
@property MBProgressHUD *hud;

@end

@implementation ActivityViewController

- (id)init {
    if (self = [super initWithClassName:@"Activity"]) {
        // Initialization code
        [NotificationHelper registerForNotification:NotificationUpdateActivityClassItem WithDelegate:self];
    }
    return self;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    PFObject *selected = [self objectAtIndexPath:indexPath];
    self.selectedActivityItem = selected;
    
    PFObject *videoObject = [selected objectForKey:@"video"];
    PFFile *videoFile = [videoObject objectForKey:@"videoFile"];
    
    self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [self.hud setLabelText:@"Loading"];
    [self.hud setDimBackground:YES];
    
    [videoFile getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
        if (error == nil) {
            // Set custom view mode
            self.hud.mode = MBProgressHUDModeCustomView;
            [self.hud hide:NO];
            
            [self loadVideo:data];
        }
    }];
}

- (void)replyAction:(id)sender {
    if ([self isSelectedQuestionRepliedBefore]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Problem"
                                                        message:@"You answered this question already!"
                                                       delegate:nil
                                              cancelButtonTitle:nil
                                              otherButtonTitles:@"OK", nil];
        [alert show];
        return;
    }
    PFUser *toUser = (PFUser *)[self.selectedActivityItem objectForKey:@"fromUser"];
    RecordVideoViewController *r = [[RecordVideoViewController alloc] initWithMode:RecordViewModeAnswer withRecipient:toUser withActivityObject:self.selectedActivityItem withQuestionVideoUrl:self.currentVideoUrl];
    self.navigationController.navigationBarHidden = YES;
    [self.navigationController pushViewController:r animated:YES];
}

- (void)playAction:(id)sender {
    [self hidePlayButton];
    [self hideReplyButton];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(videoPlayBackDidFinish:)
                                                 name:MPMoviePlayerPlaybackDidFinishNotification
                                               object:self.videoViewController.moviePlayer];
    [self.videoViewController.moviePlayer play];
    
    // update seen value
    [self updateSeenValue:[NSNumber numberWithBool:YES]];
}

- (PFTableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
                        object:(PFObject *)object {
    static NSString *identifier = @"Cell";
    PFTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[PFTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
    }
    
    UIFont *font;
    if ([object[@"seen"] boolValue])
        font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14];
    else
        font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:14];
    
    NSString *titleStringPrefix;
    NSString *objectType = object[@"type"];
    if ([objectType isEqualToString:@"question"])
        titleStringPrefix = @"A Question From ";
    else if ([objectType isEqualToString:@"answer"])
        titleStringPrefix = @"An Answer From ";
    
    NSString *titleString = [titleStringPrefix stringByAppendingString:object[@"fromUser"][@"fullname"]];
    
    NSAttributedString *labelText = [[NSAttributedString alloc] initWithString:titleString attributes: @{ NSFontAttributeName : font }];
    
    cell.textLabel.attributedText = labelText;
    cell.detailTextLabel.text = [self getLocalizedStringForDate:[object createdAt]];
    
    return cell;
}

- (PFQuery *)queryForTable {
    PFUser *currentUser = [PFUser currentUser];
    
    PFQuery *query = [PFQuery queryWithClassName:@"Activity"];
    [query includeKey:@"fromUser"];
    [query includeKey:@"video"];
    [query whereKey:@"toUser" equalTo:currentUser];
    
//    NSSortDescriptor *aDescriptor = [[NSSortDescriptor alloc] initWithKey:@"replied" ascending:YES];
//    NSSortDescriptor *bDateDescriptor = [[NSSortDescriptor alloc] initWithKey:@"createdAt" ascending:NO];
//    NSArray *sortDescriptors = @[aDescriptor, bDateDescriptor];
//    [query orderBySortDescriptors:sortDescriptors];
    
    
    [query orderByAscending:@"replied"];
    [query addDescendingOrder:@"createdAt"];
    return query;
}

- (BOOL)isSelectedQuestionRepliedBefore {
    NSNumber *isReplied = [self.selectedActivityItem objectForKey:@"replied"];
    return [isReplied boolValue];
}

- (void)updateSeenValue:(id)value {
    [self updateActivityItemValue:value withKey:@"seen"];
}

- (void)updateActivityItemValue:(id)value withKey:(NSString *)key {
    if ([value isEqual:[self.selectedActivityItem objectForKey:key]])
        return;
    [self.selectedActivityItem setObject:value forKey:key];
    [self.selectedActivityItem saveInBackground];
    
    // reload table each time we update a value
    [[self tableView] reloadData];
}

- (void)loadVideo:(NSData *)data
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *appFile = [documentsDirectory stringByAppendingPathComponent:@"MyFile.mov"];
    [data writeToFile:appFile atomically:YES];
    //and then into NSURL.
    self.currentVideoUrl = [NSURL fileURLWithPath:appFile];
    
    MPMoviePlayerViewController *mpvc = [[MPMoviePlayerViewController alloc] initWithContentURL:self.currentVideoUrl];
    self.videoViewController = mpvc;
    
    self.playButton = [self createPlayButton];
    self.replyButton = [self createReplyButton];
    
    // hide it by default until user finishes watching the video.
    [self hideReplyButton];
    
    [self.videoViewController.view addSubview:self.playButton];
    [self.videoViewController.view addSubview:self.replyButton];
    
    MPMoviePlayerController *videoController = [mpvc moviePlayer];
    videoController.fullscreen = YES;
    videoController.shouldAutoplay = NO;
    videoController.scalingMode = MPMovieScalingModeAspectFit;
    videoController.controlStyle = MPMovieControlStyleNone;
    
    [self.navigationController pushViewController:mpvc animated:YES];
}

- (void)videoPlayBackDidFinish:(NSNotification *)notification
{
    [self showPlayButton];
    [self showReplyButton];
    
    [[NSNotificationCenter defaultCenter]removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
    // Stop the video player and remove it from view
    [self.videoViewController.moviePlayer stop];
    //[self.videoViewController dismissMoviePlayerViewControllerAnimated];
    //[self.navigationController popViewControllerAnimated:YES];
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

- (NSString *)getLocalizedStringForDate:(NSDate *)date {
    // TODO
    // show the date in a better format
    return [date descriptionWithLocale:[NSLocale systemLocale]];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.navigationController setDelegate:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - NotificationDelegate

- (void)reactOnNotification:(NSNotification*)notification {
    NotificationList notificationName = [NotificationHelper getNotificationListName:notification];
    if (notificationName == NotificationUpdateActivityClassItem) {
        NSDictionary *userInfo = [notification object];
        [self updateActivityItemValue:[userInfo objectForKey:@"value"] withKey:[userInfo objectForKey:@"key"]];
    }
}

#pragma mark - UINavigationControllerDelegate

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if ([viewController isKindOfClass:[MPMoviePlayerViewController class]]) {
        MPMoviePlayerViewController *v = (MPMoviePlayerViewController *)viewController;
        //[[v moviePlayer] play];
        
    }
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
