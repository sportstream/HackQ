//
//  PFActivityObject.h
//  IntegratingFacebookTutorial
//
//  Created by Sirri Perek on 11/1/14.
//
//

#import <Parse/Parse.h>

@interface PFActivityObject : PFObject<PFSubclassing>

@property (retain) NSString *displayName;

+ (NSString *)parseClassName;

- (BOOL)canVideoBeReplied;
- (BOOL)canVideoBeShared;
- (BOOL)isQuestion;
- (BOOL)isAnswer;
- (BOOL)hasBeenRepliedBefore;
- (BOOL)isStitchedVideoAvailable;
- (void)updateSeenValue:(id)value;
- (void)updateRepliedValue:(id)value;
- (void)updateValue:(id)value withKey:(NSString *)key;

@end
