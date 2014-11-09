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
#import "AppDelegate.h"

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
    self.navigationController.navigationBar.barTintColor = [UIColor blackColor];
    [(AppDelegate *)[[UIApplication sharedApplication] delegate] hideTabBar:self.tabBarController];
    
    UIPageViewController *pageController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
    pageController.dataSource = self;
    [[pageController view] setFrame:self.view.frame];
    
    HackVideoPlayer *initialViewController = [self viewControllerAtIndex:indexPath.row];
    initialViewController.activityItem = (PFActivityObject *)[self.objects objectAtIndex:indexPath.row];
    NSArray *viewControllers = [NSArray arrayWithObject:initialViewController];
    
    [pageController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
    
    [self.navigationController pushViewController:pageController animated:YES];
    self.navigationController.navigationBar.topItem.title = @""; //just show the
    return;    

//    PFActivityObject *selected = (PFActivityObject *)[self objectAtIndexPath:indexPath];
//    self.selectedActivityItem = selected;
//    
//    PFObject *videoObject = [self.selectedActivityItem isStitchedVideoAvailable]
//                                                                                ? [selected objectForKey:@"stitchedVideo"]
//                                                                                : [selected objectForKey:@"video"];
//    
//    PFFile *videoFile = [videoObject objectForKey:@"videoFile"];
//    
//    self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
//    [self.hud setLabelText:@"Loading"];
//    [self.hud setDimBackground:YES];
//    
//    [videoFile getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
//        if (error == nil) {
//            // Set custom view mode
//            self.hud.mode = MBProgressHUDModeCustomView;
//            [self.hud hide:NO];
//            
//            [self loadVideoPlayer:data];
//        }
//    }];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50.0;
}

- (PFTableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
                        object:(PFObject *)object {
    static NSString *identifier = @"Cell";
    PFTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[PFTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
        cell.imageView.contentMode = UIViewContentModeScaleAspectFit;
    }
    
    UIFont *font;
    if ([object[@"seen"] boolValue])
        font = [UIFont fontWithName:@"HelveticaNeue-Light" size:20];
    else
        font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:20];
    
    NSString *objectType = object[@"type"];
    if ([objectType isEqualToString:@"question"])
    {
        if (object[@"replied"] == [NSNumber numberWithBool:YES])
            cell.imageView.image = [UIImage imageNamed:@"flatReplyIcon"];
        else
            cell.imageView.image = [UIImage imageNamed:@"questionIconFlat"];
    }
    else if ([objectType isEqualToString:@"answer"])
        cell.imageView.image = [UIImage imageNamed:@"answerIconFlat"];
    
    NSString *titleString = [NSString stringWithFormat:@"From %@", object[@"fromUser"][@"fullname"]];
    
    NSAttributedString *labelText = [[NSAttributedString alloc] initWithString:titleString attributes: @{ NSFontAttributeName : font }];
    
    cell.textLabel.attributedText = labelText;

    if (!cell.accessoryView)
    {
        UILabel *label = [UILabel new];
        label.frame = CGRectMake(0,0,50,50);
        label.font = [UIFont fontWithName:@"Helvetica" size:12.0];
        label.textAlignment = NSTextAlignmentRight;
        cell.accessoryView = label;
    }
    
    UILabel *label = (UILabel *)cell.accessoryView;
    label.text = [self timeAgo:[object createdAt]];

    return cell;
}

- (PFQuery *)queryForTable {
    PFUser *currentUser = [PFUser currentUser];
    
    PFQuery *query = [PFQuery queryWithClassName:@"Activity"];
    [query includeKey:@"fromUser"];
    [query includeKey:@"video"];
//    [query includeKey:@"thumbnailFile"];
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

- (void)objectsDidLoad:(NSError *)error
{
    [super objectsDidLoad:error];
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

- (NSString *)timeAgo:(NSDate *)compareDate{
    NSTimeInterval timeInterval = -[compareDate timeIntervalSinceNow];
    int temp = 0;
    NSString *result;
    if (timeInterval < 60) {
        result = [NSString stringWithFormat:@"Just now"];   //less than a minute
    }else if((temp = timeInterval/60) <60){
        result = [NSString stringWithFormat:@"%dm",temp];   //minutes ago
    }else if((temp = temp/60) <24){
        result = [NSString stringWithFormat:@"%dh",temp];   //hours ago
    }else{
        temp = temp / 24;
        result = [NSString stringWithFormat:@"%dd",temp];   //days ago
    }
    return  result;
}

#pragma mark - UIPageViewController stuff

- (HackVideoPlayer *)viewControllerAtIndex:(NSUInteger)index {

    PFActivityObject *obj = (PFActivityObject *)[self.objects objectAtIndex:index];
//    PFObject *videoObject = [obj isStitchedVideoAvailable]
//    ? [obj objectForKey:@"stitchedVideo"]
//    : [obj objectForKey:@"video"];
//    
//    PFFile *videoFile = [videoObject objectForKey:@"videoFile"];
//    HackVideoPlayer *childViewController = [[HackVideoPlayer alloc] initWithContentURL:[NSURL URLWithString:videoFile.url]];
    HackVideoPlayer *childViewController = [[HackVideoPlayer alloc] initWithObj:obj];
    childViewController.index = index;
    childViewController.activityItem = obj;

    return childViewController;
    
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    
    NSUInteger index = [(HackVideoPlayer *)viewController index];
    
    if (index == 0) {
        return nil;
    }
    
    // Decrease the index by 1 to return
    index--;
    
    return [self viewControllerAtIndex:index];
    
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    
    NSUInteger index = [(HackVideoPlayer *)viewController index];
    
    index++;
    
    if (index == [self.objects count]) {
        return nil;
    }
    
    return [self viewControllerAtIndex:index];
    
}

- (NSInteger)presentationCountForPageViewController:(UIPageViewController *)pageViewController {
    // The number of items reflected in the page indicator.
    return 0;
}

- (NSInteger)presentationIndexForPageViewController:(UIPageViewController *)pageViewController {
    // The selected item reflected in the page indicator.
    return 0;
}

#pragma - view delegates

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.topItem.title = @"Inbox";
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:68.0/255.0 green:98.0/255.0 blue:158.0/255.0 alpha:1.0];
    [(AppDelegate *)[[UIApplication sharedApplication] delegate] showTabBar:self.tabBarController];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.navigationController setDelegate:self];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.enabled = NO;
        self.navigationController.interactivePopGestureRecognizer.delegate = nil;
    }
}

@end
