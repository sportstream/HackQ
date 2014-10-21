//
//  MainMenuViewController.m
//  IntegratingFacebookTutorial
//
//  Created by Sid Mal on 10/21/14.
//
//

#import "MainMenuViewController.h"
#import "RecordVideoViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>

@interface MainMenuViewController ()

@end

@implementation MainMenuViewController

@synthesize chatButton, questionButton;

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBarHidden = YES;
}



- (IBAction)chatTap
{
    
}

- (IBAction)questionTap
{
    RecordVideoViewController *r = [[RecordVideoViewController alloc] init];
    [self.navigationController pushViewController:r animated:YES];
    return;
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
