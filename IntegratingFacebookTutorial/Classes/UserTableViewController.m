//
//  UserTableViewController.m
//  IntegratingFacebookTutorial
//
//  Created by Sirri Perek on 10/23/14.
//
//

#import "UserTableViewController.h"
#import "RecordVideoViewController.h"

@interface UserTableViewController ()

@end

@implementation UserTableViewController

- (id)init {
    if (self = [super initWithClassName:@"_User"]) {
        // Initialization code
        self.textKey = @"fullname";
    }
    return self;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    PFUser *selected = (PFUser *)[self objectAtIndexPath:indexPath];
    
    RecordVideoViewController *r = [[RecordVideoViewController alloc] initWithMode:RecordViewModeQuestion withRecipient:selected];
    self.navigationController.navigationBarHidden = YES;
    [self.navigationController pushViewController:r animated:NO];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.navigationController.navigationBarHidden = NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (PFQuery *)queryForTable {
    PFUser *currentUser = [PFUser currentUser];
    PFObject *currentUsersRole = (PFObject*)[currentUser objectForKey:@"userRole"];
    
    PFQuery *userQuery = [PFUser query];
    
    // currentUsersRole should be a valid object
    // but keeping this code
    // just to be safe
    if (currentUsersRole == nil) {
        // find out currentuser's role object. (User -> userRole)
        // locks the main thread so this eventually be removed
        NSArray *allUsers = [userQuery findObjects];
        NSInteger resultsCount = [allUsers count];
        for (int i = 0; i < resultsCount; i++)
        {
            PFObject *user = [allUsers objectAtIndex:i];
            NSString *username = [user objectForKey:@"username"];
            if ([username isEqualToString:[currentUser username]]) {
                PFObject *userRole = [user objectForKey:@"userRole"];
                currentUsersRole = userRole;
            }
        }
    }
    
    // query for other users who belong to the other role.
    userQuery = [PFUser query];
    [userQuery whereKey:@"userRole" notEqualTo:currentUsersRole];
    return userQuery;
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
