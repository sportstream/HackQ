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

- (IBAction)redoTap;
- (IBAction)saveTap;
- (IBAction)playTap;

@end
