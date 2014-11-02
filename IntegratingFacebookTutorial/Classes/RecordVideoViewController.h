//
//  RecordVideoViewController.h
//  IntegratingFacebookTutorial
//
//  Created by Sid Mal on 10/21/14.
//
//

#import <UIKit/UIKit.h>
#import "PFActivityObject.h"

@interface RecordVideoViewController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

typedef NS_ENUM(NSInteger, RecordViewMode) {
    RecordViewModeQuestion,
    RecordViewModeAnswer
};

@property (nonatomic, retain) IBOutlet UIImageView *imageView;
@property (nonatomic, retain) IBOutlet UIView *videoView;
@property (nonatomic, retain) IBOutlet UIView *obscureView;
@property (nonatomic, retain) IBOutlet UIButton *playButton;
@property (nonatomic, retain) PFUser *toUser;

- (id)initWithMode:(RecordViewMode)mode withRecipient:(PFUser *)toUser;
- (id)initWithMode:(RecordViewMode)mode withRecipient:(PFUser *)toUser withActivityObject:(PFActivityObject *)activityObject withQuestionVideoUrl:(NSURL *)questionVideoUrl;
- (IBAction)redoTap;
- (IBAction)saveTap;
- (IBAction)playTap;
- (IBAction)xTap;

@end
