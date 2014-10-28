//
//  RecordVideoViewController.h
//  IntegratingFacebookTutorial
//
//  Created by Sid Mal on 10/21/14.
//
//

#import <UIKit/UIKit.h>

@interface RecordVideoViewController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic, retain) IBOutlet UIImageView *imageView;
@property (nonatomic, retain) IBOutlet UIView *videoView;
@property (nonatomic, retain) IBOutlet UIView *obscureView;
@property (nonatomic, retain) IBOutlet UIButton *playButton;
@property (nonatomic, retain) PFUser *toUser;

- (IBAction)redoTap;
- (IBAction)saveTap;
- (IBAction)playTap;
- (IBAction)xTap;

@end
