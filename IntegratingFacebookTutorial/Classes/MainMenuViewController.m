//
//  MainMenuViewController.m
//  IntegratingFacebookTutorial
//
//  Created by Sid Mal on 10/21/14.
//
//

#import "MainMenuViewController.h"
#import "RecordVideoViewController.h"
#import "UserDetailsViewController.h"
#import "UserTableViewController.h"
#import "ActivityViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>

@interface MainMenuViewController ()
@property (nonatomic, retain) UITabBarController *tab;

@end

@implementation MainMenuViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBarHidden = YES;
    self.tab=[[UITabBarController alloc]init];
    
    // FirstViewController
    ActivityViewController *fvc = [[ActivityViewController alloc] init];
    UINavigationController *firstNavigationController = [[UINavigationController alloc]
                                                     initWithRootViewController:fvc];
    fvc.title=@"Inbox";
    fvc.tabBarItem.image=[UIImage imageNamed:@"bubbleIcon.png"];
    
    //SecondViewController
    UserTableViewController *svc = [[UserTableViewController alloc] init];

    UINavigationController *secondNavigationController = [[UINavigationController alloc]
                            initWithRootViewController:svc];
    svc.title=@"Ask a Question";
    svc.tabBarItem.image=[UIImage imageNamed:@"questionMarkIcon.png"];
    
    self.tab.viewControllers=[NSArray arrayWithObjects:firstNavigationController, secondNavigationController, nil];
    
    [self.view addSubview:self.tab.view];
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
