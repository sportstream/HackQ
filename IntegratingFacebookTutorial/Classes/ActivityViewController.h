//
//  ActivityViewController.h
//  IntegratingFacebookTutorial
//
//  Created by Sirri Perek on 10/27/14.
//
//

#import <Parse/Parse.h>
#import "NotificationDelegate.h"
#import "NotificationHelper.h"

@interface ActivityViewController : PFQueryTableViewController <UINavigationControllerDelegate, NotificationDelegate>

@end
