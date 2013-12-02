/*
 * Copyright 2013 Devin Collins <devin@imdevinc.com>
 *
 * This file is part of MyTLC Sync.
 *
 * MyTLC Sync is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * MyTLC Sync is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with MyTLC Sync.  If not, see <http://www.gnu.org/licenses/>.
 */

#import "mytlcAppDelegate.h"
#import "mytlcMainViewController.h"

@implementation mytlcAppDelegate

@synthesize timerAppBg;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
//    [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
//
    return YES;
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
//    NSLog(@"Starting");
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    
//    NSString* time = [defaults valueForKey:@"sync_time"];
//    
//    NSUInteger day = [defaults integerForKey:@"sync_day"];
//    
//    NSCalendar* cal = [NSCalendar currentCalendar];
//    
//    NSDate* date = [NSDate date];
//    
//    NSDateComponents* components = [cal components:(NSWeekdayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit) fromDate:date];
//    
//    if (day != 8 && day!= 0 && day != [components weekday])
//    {
//        completionHandler(UIBackgroundFetchResultNoData);
//        
//        return;
//    }
    
//    NSDateFormatter* df = [[NSDateFormatter alloc] init];
//    
//    [df setDateFormat:@"h:mm a"];
//    
//    NSDate* checkDate = [df dateFromString:time];
//    
//    NSInteger now_hour = [components hour];
//    
//    NSInteger now_minute = [components minute];
//    
//    components = [cal components:(NSHourCalendarUnit | NSMinuteCalendarUnit) fromDate:checkDate];
//    
//    NSInteger check_hour = [components hour];
//    
//    NSInteger check_minute = [components minute];
//    
//    if (check_hour != now_hour || check_minute != now_minute)
//    {
//        completionHandler(UIBackgroundFetchResultNoData);
//        
//        return;
//    }
    
//    UINavigationController *navigationController = (UINavigationController*) self.window.rootViewController;
//    
//    id topViewController = navigationController.topViewController;
//    
//    if ([topViewController isKindOfClass:[mytlcMainViewController class]])
//    {
//        [(mytlcMainViewController*)topViewController autologin:completionHandler];
//    }
}

@end
