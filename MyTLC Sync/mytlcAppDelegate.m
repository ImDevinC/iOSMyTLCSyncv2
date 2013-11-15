//
//  mytlcAppDelegate.m
//  MyTLC Sync
//
//  Created by Devin Collins on 10/25/13.
//  Copyright (c) 2013 Layer 8 Applications. All rights reserved.
//

#import "mytlcAppDelegate.h"
#import "mytlcMainViewController.h"

@implementation mytlcAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:30.0];

    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSString* time = [defaults valueForKey:@"sync_time"];
    
    NSUInteger day = [defaults integerForKey:@"sync_day"];
    
    NSCalendar* cal = [NSCalendar currentCalendar];
    
    NSDate* date = [NSDate date];
    
    NSDateComponents* components = [cal components:(NSWeekdayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit) fromDate:date];
    
    if (day != 8 && day!= 0 && day != [components weekday])
    {
        completionHandler(UIBackgroundFetchResultNoData);
        
        return;
    }
    
    NSDateFormatter* df = [[NSDateFormatter alloc] init];
    
    [df setDateFormat:@"h:mm a"];
    
    NSDate* checkDate = [df dateFromString:time];
    
    NSInteger now_hour = [components hour];
    
    NSInteger now_minute = [components minute];
    
    components = [cal components:(NSHourCalendarUnit | NSMinuteCalendarUnit) fromDate:checkDate];
    
    NSInteger check_hour = [components hour];
    
    NSInteger check_minute = [components minute];
    
    if (check_hour != now_hour || check_minute != now_minute)
    {
        completionHandler(UIBackgroundFetchResultNoData);
        
        return;
    }
    
    UINavigationController *navigationController = (UINavigationController*) self.window.rootViewController;
    
    id topViewController = navigationController.topViewController;
    
    if ([topViewController isKindOfClass:[mytlcMainViewController class]])
    {
        [(mytlcMainViewController*)topViewController autologin];
    }
    
    completionHandler(UIBackgroundFetchResultNewData);
}

@end
