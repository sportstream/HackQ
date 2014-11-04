/**
 * Copyright (c) 2014, Parse, LLC. All rights reserved.
 *
 * You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
 * copy, modify, and distribute this software in source code or binary form for use
 * in connection with the web services and APIs provided by Parse.

 * As with any software that integrates with the Parse platform, your use of
 * this software is subject to the Parse Terms of Service
 * [https://www.parse.com/about/terms]. This copyright notice shall be
 * included in all copies or substantial portions of the software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
 * FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
 * COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
 * IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 *
 */

#import "AppDelegate.h"

#import <Parse/Parse.h>
#import <ParseFacebookUtils/PFFacebookUtils.h>

#import "LoginViewController.h"
#import "MainMenuViewController.h"
#import "PFActivityObject.h"


@implementation AppDelegate

#pragma mark -
#pragma mark UIApplicationDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    // register PFActivityObject as a subclass so Parse always use PFActivityObject
    // whenever a record related to Activity table is being read/written.
    [PFActivityObject registerSubclass];
    
    // ****************************************************************************
    // Fill in with your Parse credentials:
    // ****************************************************************************
    [Parse setApplicationId:@"BhVTelFBqMm2mGl2YbfPmSkHLgJOQhzPIazwpSdk"
                  clientKey:@"5EfKewvBPymPtQhn5WtBJliIQYLrYov9ublLVpEG"];

    // ****************************************************************************
    // Your Facebook application id is configured in Info.plist.
    // ****************************************************************************
    [PFFacebookUtils initializeFacebook];

    // Override point for customization after application launch
    id vc;
    if ([PFUser currentUser] && [PFFacebookUtils isLinkedWithUser:[PFUser currentUser]]) {
        vc = [[MainMenuViewController alloc] init];
    }
    else
        vc = [[LoginViewController alloc] init];
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    [[UINavigationBar appearance] setBarTintColor:[UIColor colorWithRed:68.0/255.0 green:98.0/255.0 blue:158.0/255.0 alpha:1.0]];
    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                [UIColor whiteColor],
                                NSForegroundColorAttributeName, nil];
    [[UIBarButtonItem appearance] setTitleTextAttributes: attributes
                                                forState: UIControlStateNormal];
    
    NSDictionary *navBarAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                      [UIColor whiteColor],
                                      NSForegroundColorAttributeName, nil];
    [[UINavigationBar appearance] setTitleTextAttributes: navBarAttributes];
    
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];

    self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:vc];
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];

    return YES;
}

#pragma mark - facebook graph api related

- (void)requestPublishPermissions:(void (^) (BOOL succeed)) block {

    FBSession *activeSession = [PFFacebookUtils session];
    BOOL canPublish = !([activeSession.permissions indexOfObject:@"publish_actions"] == NSNotFound);
    
    if (activeSession && activeSession.isOpen && !canPublish) {
        [PFFacebookUtils reauthorizeUser:[PFUser currentUser] withPublishPermissions:@[@"publish_actions"] audience:FBSessionDefaultAudienceOnlyMe block:^(BOOL succeed, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                block(succeed);
            });
        }];
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        block(canPublish);
    });
}

- (void)postVideoToFacebook:(NSData *)videoData withCallback:(void (^)(BOOL succeed))callback {
    [self requestPublishPermissions:^(BOOL succeed){
        if (succeed) {
            NSDictionary *params = @{
                                     @"video.mov" : videoData,
                                     @"contentType" : @"video/quicktime",
                                     @"title": @"Video Q&A"
                                     };
            
           [FBRequestConnection startWithGraphPath:@"me/videos" parameters:params HTTPMethod:@"POST" completionHandler:
            ^(FBRequestConnection *connection, id result, NSError *error){
                if(result)
                    dispatch_async(dispatch_get_main_queue(), ^{
                        callback(YES);
                    });
                else
                    dispatch_async(dispatch_get_main_queue(), ^{
                        callback(NO);
                    });
            }];
            
            
            
            //            FBRequestConnection *connection = [[FBRequestConnection alloc] init];
            //            connection.errorBehavior = FBRequestConnectionErrorBehaviorReconnectSession
            //            | FBRequestConnectionErrorBehaviorAlertUser
            //            | FBRequestConnectionErrorBehaviorRetry;
            //            [connection addRequest:[FBRequest requestWithGraphPath:@"me/videos" parameters:params HTTPMethod:@"POST"] completionHandler:^(FBRequestConnection *connection, id result, NSError *error){
            //                if(result)
            //                    dispatch_async(dispatch_get_main_queue(), ^{
            //                        callback(YES);
            //                    });
            //                else
            //                    dispatch_async(dispatch_get_main_queue(), ^{
            //                        callback(NO);
            //                    });
            //            }];
            //            [connection start];
        }
        else
            dispatch_async(dispatch_get_main_queue(), ^{
                callback(succeed);
            });
    }];
}

#pragma mark - tab bar methods

- (void) hideTabBar:(UITabBarController *) tabbarcontroller
{
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.5];
    float fHeight = screenRect.size.height;
    if(  UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation) )
    {
        fHeight = screenRect.size.width;
    }
    
    for(UIView *view in tabbarcontroller.view.subviews)
    {
        if([view isKindOfClass:[UITabBar class]])
        {
            [view setFrame:CGRectMake(view.frame.origin.x, fHeight, view.frame.size.width, view.frame.size.height)];
        }
        else
        {
            [view setFrame:CGRectMake(view.frame.origin.x, view.frame.origin.y, view.frame.size.width, fHeight)];
            view.backgroundColor = [UIColor blackColor];
        }
    }
    [UIView commitAnimations];
}

- (void) showTabBar:(UITabBarController *) tabbarcontroller
{
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    float fHeight = screenRect.size.height - tabbarcontroller.tabBar.frame.size.height;
    
    if(UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation))
    {
        fHeight = screenRect.size.width - tabbarcontroller.tabBar.frame.size.height;
    }
    
    for(UIView *view in tabbarcontroller.view.subviews)
    {
        if([view isKindOfClass:[UITabBar class]])
        {
            [view setFrame:CGRectMake(view.frame.origin.x, fHeight, view.frame.size.width, view.frame.size.height)];
        }
        else
        {
            [view setFrame:CGRectMake(view.frame.origin.x, view.frame.origin.y, view.frame.size.width, fHeight)];
        }
    }
}

// ****************************************************************************
// App switching methods to support Facebook Single Sign-On.
// ****************************************************************************
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    return [FBAppCall handleOpenURL:url
                  sourceApplication:sourceApplication
                        withSession:[PFFacebookUtils session]];
} 

- (void)applicationDidBecomeActive:(UIApplication *)application {
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
    [FBAppCall handleDidBecomeActiveWithSession:[PFFacebookUtils session]];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
    [[PFFacebookUtils session] close];
}

@end
