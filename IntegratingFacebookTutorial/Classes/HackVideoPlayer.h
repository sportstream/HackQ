//
//  HackVideoPlayer.h
//  IntegratingFacebookTutorial
//
//  Created by Sirri Perek on 11/1/14.
//
//

#import <MediaPlayer/MediaPlayer.h>
#import "PFActivityObject.h"
#import "NotificationDelegate.h"

@interface HackVideoPlayer : MPMoviePlayerViewController <NotificationDelegate>

@property (nonatomic, retain) PFActivityObject *activityItem;
@property NSURL *currentVideoURL;

- (id)initWithData:(NSData *)data;
- (instancetype)initWithContentURL:(NSURL *)url;

@end
