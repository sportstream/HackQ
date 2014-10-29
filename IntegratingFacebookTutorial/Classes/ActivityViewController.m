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

@property MBProgressHUD *hud;

@end

@implementation ActivityViewController

- (id)init {
    if (self = [super initWithClassName:@"Activity"]) {
        // Initialization code
    }
    return self;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.navigationController setDelegate:self];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    PFObject *selected = [self objectAtIndexPath:indexPath];
    
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
    videoController.fullscreen = YES;
    videoController.shouldAutoplay = NO;
    videoController.scalingMode = MPMovieScalingModeAspectFit;
    videoController.controlStyle = MPMovieControlStyleNone;
    
    [self.navigationController pushViewController:mpvc animated:YES];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(videoPlayBackDidFinish:)
                                                 name:MPMoviePlayerPlaybackDidFinishNotification
                                               object:videoController];
}

- (void)videoPlayBackDidFinish:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter]removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
    // Stop the video player and remove it from view
    [self.videoViewController.moviePlayer stop];
    [self.videoViewController dismissMoviePlayerViewControllerAnimated];
    [self.navigationController popViewControllerAnimated:YES];
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

- (NSString *)getLocalizedStringForDate:(NSDate *)date {
    // TODO
    // show the date in a better format
    return [date descriptionWithLocale:[NSLocale systemLocale]];
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


#pragma mark - UINavigationControllerDelegate

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if ([viewController isKindOfClass:[MPMoviePlayerViewController class]]) {
        MPMoviePlayerViewController *v = (MPMoviePlayerViewController *)viewController;
        [[v moviePlayer] play];
        
    }
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
