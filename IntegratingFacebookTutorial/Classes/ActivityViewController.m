//
//  ActivityViewController.m
//  IntegratingFacebookTutorial
//
//  Created by Sirri Perek on 10/27/14.
//
//

#import "ActivityViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "MBProgressHUD.h"
#import "PFActivityObject.h"
#import "HackVideoPlayer.h"

@interface ActivityViewController ()

@property MPMoviePlayerViewController *videoViewController;

@property PFActivityObject *selectedActivityItem;
@property MBProgressHUD *hud;

@end

@implementation ActivityViewController

- (id)init {
    if (self = [super initWithClassName:@"Activity"]) {
        // Initialization code
        [NotificationHelper registerForNotification:NotificationActivityItemUpdated WithDelegate:self];
    }
    return self;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    PFActivityObject *selected = (PFActivityObject *)[self objectAtIndexPath:indexPath];
    self.selectedActivityItem = selected;
    
    PFObject *videoObject = [self.selectedActivityItem isStitchedVideoAvailable]
                                                                                ? [selected objectForKey:@"stitchedVideo"]
                                                                                : [selected objectForKey:@"video"];
    
    PFFile *videoFile = [videoObject objectForKey:@"videoFile"];
    
    self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [self.hud setLabelText:@"Loading"];
    [self.hud setDimBackground:YES];
    
    [videoFile getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
        if (error == nil) {
            // Set custom view mode
            self.hud.mode = MBProgressHUDModeCustomView;
            [self.hud hide:NO];
            
            [self loadVideoPlayer:data];
        }
    }];
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
    [query includeKey:@"stitchedVideo"];
    [query whereKey:@"toUser" equalTo:currentUser];
    
//    NSSortDescriptor *aDescriptor = [[NSSortDescriptor alloc] initWithKey:@"replied" ascending:YES];
//    NSSortDescriptor *bDateDescriptor = [[NSSortDescriptor alloc] initWithKey:@"createdAt" ascending:NO];
//    NSArray *sortDescriptors = @[aDescriptor, bDateDescriptor];
//    [query orderBySortDescriptors:sortDescriptors];
    
    
    [query orderByAscending:@"replied"];
    [query addDescendingOrder:@"createdAt"];
    return query;
}

- (void)loadVideoPlayer:(NSData *)data
{
    HackVideoPlayer *videoPlayer = [[HackVideoPlayer alloc] initWithData:data];
    videoPlayer.activityItem = self.selectedActivityItem;
    
    self.videoViewController = videoPlayer;
    
    [self.navigationController pushViewController:videoPlayer animated:YES];
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
    if (notificationName == NotificationActivityItemUpdated) {
        [self.tableView reloadData];
    }
}

#pragma mark - UINavigationControllerDelegate

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if ([viewController isKindOfClass:[HackVideoPlayer class]]) {
        HackVideoPlayer *v = (HackVideoPlayer *)viewController;
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
