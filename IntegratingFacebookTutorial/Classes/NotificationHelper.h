//
//  NotificationHelper.h
//  IntegratingFacebookTutorial
//
//  Created by Sirri Perek on 10/29/14.
//
//

#import <Foundation/Foundation.h>
#import "NotificationDelegate.h"

typedef NS_ENUM(NSInteger, NotificationList) {
    NotificationActivityItemUpdated,
    NotificationQuestionVideoURLUpdated
};

@interface NotificationHelper : NSObject

+ (void)pushNotification:(NotificationList)notification;
+ (void)pushNotification:(NotificationList)notification WithObject:(id)object;
+ (void)registerForNotification:(NotificationList)notification WithDelegate:(id)delegate;
+ (void)unregisterForNotification:(id)delegate;

+ (NotificationList)getNotificationListName:(NSNotification *)notification;

@end