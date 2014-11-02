//
//  PFActivityObject.m
//  IntegratingFacebookTutorial
//
//  Created by Sirri Perek on 11/1/14.
//
//

#import "PFActivityObject.h"
#import <Parse/PFObject+Subclass.h>
#import "NotificationHelper.h"

@implementation PFActivityObject
@dynamic displayName;

+ (NSString *)parseClassName {
    return @"Activity";
}

- (BOOL)canVideoBeReplied {
    return [self isQuestion] && ![self hasBeenRepliedBefore];
}

- (BOOL)canVideoBeShared {
    return [self isStitchedVideoAvailable];
}

- (BOOL)isQuestion {
    NSString *type = [self objectForKey:@"type"];
    return [type isEqualToString:@"question"];
}

- (BOOL)isAnswer {
    NSString *type = [self objectForKey:@"type"];
    return [type isEqualToString:@"answer"];
}

- (BOOL)isStitchedVideoAvailable {
    return [(PFObject *)[self objectForKey:@"stitchedVideo"] isDataAvailable];
}

- (BOOL)hasBeenRepliedBefore {
    NSNumber *isReplied = [self objectForKey:@"replied"];
    return [isReplied boolValue];
}

- (void)updateSeenValue:(id)value {
    [self updateValue:value withKey:@"seen"];
}

- (void)updateRepliedValue:(id)value {
    [self updateValue:value withKey:@"replied"];
}

- (void)updateValue:(id)value withKey:(NSString *)key {
    if ([value isEqual:[self objectForKey:key]])
        return;
    [self setObject:value forKey:key];
    
    // fire an event
    [NotificationHelper pushNotification:NotificationActivityItemUpdated];
    
    [self saveInBackground];
}


@end
