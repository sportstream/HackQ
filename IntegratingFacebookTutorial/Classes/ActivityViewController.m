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

@interface ActivityViewController ()

@property MPMoviePlayerViewController *videoViewController;

@end

@implementation ActivityViewController

- (id)init {
    if (self = [super initWithClassName:@"Activity"]) {
        // Initialization code
        self.textKey = @"fromUser";
    }
    return self;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    PFObject *selected = [self objectAtIndexPath:indexPath];
    
    PFObject *videoObject = [selected objectForKey:@"video"];
    PFFile *videoFile = [videoObject objectForKey:@"videoFile"];
    [videoFile getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
        if (error == nil) {
            [self playVideo:data];
        }
    }];
}

- (void)playVideo:(NSData *)data
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *appFile = [documentsDirectory stringByAppendingPathComponent:@"MyFile.m4v"];
    [data writeToFile:appFile atomically:YES];
    //and then into NSURL.
    NSURL *url = [NSURL fileURLWithPath:appFile];
    
    MPMoviePlayerViewController *mpvc = [[MPMoviePlayerViewController alloc] initWithContentURL:url];
    self.videoViewController = mpvc;
    
    MPMoviePlayerController *videoController = [mpvc moviePlayer];
    [videoController setFullscreen:YES];
    videoController.scalingMode = MPMovieScalingModeAspectFit;
    videoController.controlStyle = MPMovieControlStyleNone;
    
    [self.navigationController pushViewController:mpvc animated:YES];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(videoPlayBackDidFinish:)
                                                 name:MPMoviePlayerPlaybackDidFinishNotification
                                               object:videoController];
    [videoController play];
}

- (void)videoPlayBackDidFinish:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter]removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
    // Stop the video player and remove it from view
    //[self.videoViewController.moviePlayer stop];
    [self.videoViewController dismissMoviePlayerViewControllerAnimated];
}

- (PFTableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
                        object:(PFObject *)object {
    static NSString *identifier = @"Cell";
    PFTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[PFTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    cell.textLabel.text = object[@"fromUser"][@"fullname"];
    
    
    return cell;
    
}

- (PFQuery *)queryForTable {
    PFUser *currentUser = [PFUser currentUser];
    
    PFQuery *query = [PFQuery queryWithClassName:@"Activity"];
    [query includeKey:@"fromUser"];
    [query includeKey:@"video"];
    [query whereKey:@"toUser" equalTo:currentUser];
    
    return query;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
