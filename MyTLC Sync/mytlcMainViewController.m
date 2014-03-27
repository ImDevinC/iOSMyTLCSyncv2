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

#import "mytlcMainViewController.h"
#import "mytlcCalendarHandler.h"
#import <Security/Security.h>


@interface mytlcMainViewController ()

@end

@implementation mytlcMainViewController

@synthesize btnLogin;
@synthesize txtPassword;
@synthesize txtUsername;
@synthesize aivStatus;
@synthesize lblStatus;
@synthesize chkSave;
@synthesize scrollView;

mytlcCalendarHandler* ch = nil;
BOOL showNotifications = NO;

- (void) checkStatus
{
    while (![ch hasCompleted] || [aivStatus isAnimating])
    {
        if (![ch hasNewMessage] && ![ch hasCompleted]){
            continue;
        }
        
        [ch setMessageRead];
        
        [self performSelectorOnMainThread:@selector(displayMessage) withObject:FALSE waitUntilDone:false];
    }
}

- (void) deleteEvent
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults removeObjectForKey:@"shifts"];
    
    [defaults synchronize];
    
    [lblStatus setText:@"Events cache cleared, remove events from the calendar manually"];
}

- (void) displayAlert:(NSString*) message
{
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"MyTLC Sync" message:message delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil];
    
    [alert show];
}

- (void) displayMessage
{
    [lblStatus setText:[ch getMessage]];
    
    if ([ch hasCompleted])
    {
        if (showNotifications)
        {
            UILocalNotification* notification = [[UILocalNotification alloc] init];
            
            notification.fireDate = [NSDate date];
            
            notification.alertBody = [ch getMessage];
            
            notification.timeZone = [NSTimeZone defaultTimeZone];
            
            [[UIApplication sharedApplication] scheduleLocalNotification:notification];
        }
        
        [aivStatus stopAnimating];
        
        [btnLogin setEnabled:YES];
        
        if (self.fetchCompletionHandler)
        {
            self.fetchCompletionHandler(UIBackgroundFetchResultNewData);
            
            self.fetchCompletionHandler = nil;
        }
    }
}

- (IBAction) hideKeyboard
{
    [txtUsername resignFirstResponder];
    [txtPassword resignFirstResponder];
    [scrollView setContentOffset:CGPointMake(0,0) animated:YES];
}

- (void) autologin:(void (^)(UIBackgroundFetchResult))completionHandler
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];

    NSString* username = [defaults valueForKey:@"username"];
    
    NSString* password = [defaults valueForKey:@"password"];
    
    self.fetchCompletionHandler = completionHandler;
    
    showNotifications = YES;
    
    [self login:username password:password];
}

- (IBAction) manualLogin
{
    [self hideKeyboard];
    
    [lblStatus setText:@""];
    
    NSString* username = [txtUsername text];
    NSString* password = [txtPassword text];
    
    if ([username isEqualToString:@""] || [password isEqualToString:@""])
    {
        [self displayAlert:@"Please enter a username and password"];
        
        return;
    }
    
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    
    if ([chkSave isOn]) {
        [defaults setValue:username forKey:@"username"];
        
        [defaults setValue:password forKey:@"password"];
    } else {
        [defaults removeObjectForKey:@"username"];
        
        [defaults removeObjectForKey:@"password"];
    }
    
    [defaults synchronize];
    
    [self login:username password:password];
}

- (void)login:(NSString*)username password:(NSString*) password
{
    NSDictionary *login = [[NSDictionary alloc] initWithObjectsAndKeys:username, @"username", password, @"password", nil];
    
    [btnLogin setEnabled:NO];
    
    [aivStatus startAnimating];
    
    NSOperationQueue* backgroundQueue = [NSOperationQueue new];
    
    ch = [[mytlcCalendarHandler alloc] init];
    
    NSInvocationOperation* operation = [[NSInvocationOperation alloc] initWithTarget:ch selector:@selector(runEvents:) object:login];
    
    [backgroundQueue addOperation:operation];
    
    operation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(checkStatus) object:nil];
    
    [backgroundQueue addOperation:operation];
}

- (BOOL) textFieldShouldReturn:(UITextField*) textField
{
    if ([textField isEqual:txtUsername])
    {
        [textField resignFirstResponder];
        [txtPassword becomeFirstResponder];
        return NO;
    } else {
        [textField resignFirstResponder];
        [scrollView setContentOffset:CGPointMake(0,0) animated:YES];
        [self manualLogin];
    }
    
    return YES;
}

- (IBAction)unwindToMain:(UIStoryboardSegue *)segue
{

}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void) textFieldDidBeginEditing:(UITextField*) textField
{
    [scrollView setContentOffset:CGPointMake(0, txtUsername.center.y - 120) animated:YES];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    UIGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];
    
    [self.view addGestureRecognizer:tap];
    
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    
    BOOL firstRun = ![defaults boolForKey:@"firstRun"];
    
    NSInteger version = [defaults integerForKey:@"version"];
    
    if (version < 1)
    {
        [defaults setValue:@"Work@BestBuy" forKey:@"title"];
        
        [self displayAlert:@"RC 1.3 Changelog:\n - Added custom event titles"];
        
        [defaults setInteger:1 forKey:@"version"];
        
        [defaults synchronize];
        
    }
    
    if (firstRun) {
        [defaults setBool:YES forKey:@"firstRun"];
        
        [defaults setValue:@"default" forKey:@"calendar_id"];
        
        [defaults setInteger:0 forKey:@"alarm"];
        
        [defaults setInteger:7 forKey:@"sync_day"];
        
        [defaults setValue:@"12:00 AM" forKey:@"sync_time"];
        
        [defaults setValue:@"Work@BestBuy" forKey:@"title"];
        
        [defaults synchronize];
    } else {
        NSString* username = [defaults valueForKey:@"username"];
        
        NSString* password = [defaults valueForKey:@"password"];
        
        if (username != nil && password != nil) {
            [txtUsername setText:username];
            
            [txtPassword setText:password];
            
            [chkSave setOn:YES];
        } else {
            [chkSave setOn:NO];
        }
    }
    
}

- (void) viewDidAppear:(BOOL)animated
{
    [scrollView setContentOffset:CGPointMake(0,0) animated:NO];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
