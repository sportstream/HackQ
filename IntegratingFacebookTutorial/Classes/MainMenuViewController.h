//
//  MainMenuViewController.h
//  IntegratingFacebookTutorial
//
//  Created by Sid Mal on 10/21/14.
//
//

#import <UIKit/UIKit.h>

@interface MainMenuViewController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate>


@property (nonatomic, retain) IBOutlet UIButton *chatButton;
@property (nonatomic, retain) IBOutlet UIButton *questionButton;

- (IBAction)chatTap;
- (IBAction)questionTap;

@end
