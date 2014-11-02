//
//  HackVideoPlayer.h
//  IntegratingFacebookTutorial
//
//  Created by Sirri Perek on 11/1/14.
//
//

#import <MediaPlayer/MediaPlayer.h>
#import "PFActivityObject.h"

@interface HackVideoPlayer : MPMoviePlayerViewController

@property (nonatomic, retain) PFActivityObject *activityItem;

- (id)initWithData:(NSData *)data;
- (instancetype)initWithContentURL:(NSURL *)url;

@end
