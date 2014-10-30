//
//  NotificationDelegate.h
//  IntegratingFacebookTutorial
//
//  Created by Sirri Perek on 10/29/14.
//
//

#import <Foundation/Foundation.h>

@protocol NotificationDelegate

- (void)reactOnNotification:(NSNotification*)notification;

@end
