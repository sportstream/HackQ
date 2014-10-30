//
//  NotificationHelper.m
//  IntegratingFacebookTutorial
//
//  Created by Sirri Perek on 10/29/14.
//
//

#import "NotificationHelper.h"

NSString *const seperator = @"_";
NSString *const notificationNamePrefix = @"NotificationName";

@implementation NotificationHelper

+ (void)pushNotification:(NotificationList)notification WithObject:(id)object
{
    [[NSNotificationCenter defaultCenter] postNotificationName:[self convertNotificationListToString:notification] object:object];
}

+ (void)registerForNotification:(NotificationList)notification WithDelegate:(id)delegate
{
    [[NSNotificationCenter defaultCenter] addObserver:delegate selector:@selector(reactOnNotification:)
                                                 name:[self convertNotificationListToString:notification] object:nil];
}

+ (void)unregisterForNotification:(id)delegate
{
    [[NSNotificationCenter defaultCenter] removeObserver:delegate];
}

+ (NSString *)convertNotificationListToString:(NotificationList)nListItem
{
    NSString *notificationName = [NSString stringWithFormat:@"%ld", nListItem];
    return [NSString stringWithFormat:@"%@%@%@", notificationNamePrefix, seperator, notificationName];
}

+ (NotificationList)getNotificationListName:(NSNotification *)notification
{
    NSString *name = [notification name];
    NSArray *splitted = [name componentsSeparatedByString:seperator];
    NSString *nListString = [splitted objectAtIndex:1];
    NotificationList nList = [[nListString stringByReplacingOccurrencesOfString:@" " withString:@""] longLongValue];
    return nList;
}

@end