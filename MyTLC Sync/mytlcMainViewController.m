//
//  mytlcMainViewController.m
//  MyTLC Sync
//
//  Created by Devin Collins on 10/25/13.
//  Copyright (c) 2013 Layer 8 Applications. All rights reserved.
//

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

mytlcCalendarHandler* ch = nil;

- (void) checkStatus
{
    while (true)
    {
        if (![ch hasNewMessage]){
            continue;
        }
        
        [self performSelectorOnMainThread:@selector(displayMessage) withObject:FALSE waitUntilDone:false];
        
        if ([ch hasCompleted])
        {
            break;
        }
    }
}

- (void) displayAlert:(NSString*) message
{
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"MyTLC Sync" message:message delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil];
    
    [alert show];
}

- (void) displayMessage
{
    [lblStatus setText:[ch getMessage]];
    
    [ch setMessageRead];
    
    if ([ch hasCompleted])
    {
        [aivStatus stopAnimating];
        
        [btnLogin setEnabled:YES];
    }
}

- (IBAction) hideKeyboard
{
    [txtUsername resignFirstResponder];
    [txtPassword resignFirstResponder];
}

- (void) autologin
{
    NSLog(@"Starting");
    
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];

    NSString* username = [defaults valueForKey:@"username"];
    
    NSString* password = [defaults valueForKey:@"password"];
    
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
    
    [btnLogin setEnabled:NO];
    
    [aivStatus startAnimating];
    
    [self login:username password:password];
}

- (void)login:(NSString*)username password:(NSString*) password
{
    NSDictionary *login = [[NSDictionary alloc] initWithObjectsAndKeys:username, @"username", password, @"password", NO, @"showNotification", nil];
    
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
        [self manualLogin];
        return NO;
    }
    
    return YES;
}

- (IBAction)unwindToMain:(UIStoryboardSegue *)segue
{
    [self setupAutoRun];
}

- (void) setupAutoRun
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    
    int sync_day = [defaults integerForKey:@"sync_day"];
    
    NSString* sync_time = [defaults valueForKey:@"sync_time"];
    
    if (sync_day == 7 || [sync_time isEqualToString:@""])
    {
        return;
    }
    
    int repeat = 60 * 60 * 24 * 7;
    
    if (sync_day == 8)
    {
        repeat = 60 * 60 * 24;
    }
    NSString* username = [defaults valueForKey:@"username"];
    
    NSString* password = [defaults valueForKey:@"password"];

    if (username != nil && ![username isEqualToString:@""] && password != nil && ![password isEqualToString:@""]) {
        sync_day++;
        
        NSDate* date = [[NSDate alloc] init];
        
        NSCalendar* calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
        
        NSDateComponents* components = [calendar components:NSWeekdayCalendarUnit fromDate:date];
        
        if (sync_day == 9)
        {
            [components setWeekday:[components weekday]];
        }
        else
        {
            [components setWeekday:sync_day - [components weekday]];
        }

        
        date = [calendar dateByAddingComponents:components toDate:date options:0];
        
        NSDateFormatter* df = [[NSDateFormatter alloc] init];
        
        [df setDateFormat:@"h:mm a"];
        
        NSDate* time = [df dateFromString:sync_time];
        
        NSDateComponents* timeComponents = [calendar components:(NSHourCalendarUnit | NSMinuteCalendarUnit) fromDate: time];
        
        components = [calendar components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit) fromDate:date];
        
        [components setHour:[timeComponents hour]];
        
        [components setMinute:[timeComponents minute]];
        
        date = [calendar dateFromComponents:components];

         if ([date earlierDate:[[NSDate alloc] init]] == date)
        {
            NSLog(@"Timer Date: %@\nCurrent Time: %@", date, [[NSDate alloc] init]);
            if (sync_day == 9)
            {
                [components setDay:[components day] + 1];
            }
            else
            {
                [components setDay:[components day] + 7];
            }
            
            date = [calendar dateFromComponents:components];
        }
        
        NSTimer* timer = [[NSTimer alloc] initWithFireDate:date interval:repeat target:self selector:@selector(autologin) userInfo:nil repeats:YES];
        
        NSRunLoop* runner = [NSRunLoop currentRunLoop];
        
        [runner addTimer:timer forMode:NSDefaultRunLoopMode];
        
        NSLog(@"Timer added at: %@", date);
    }
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    UIGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];
    
    [self.view addGestureRecognizer:tap];
    
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    
    BOOL firstRun = ![defaults boolForKey:@"firstRun"];
    
    if (firstRun) {
        [defaults setBool:YES forKey:@"firstRun"];
        
        [defaults setValue:@"default" forKey:@"calendar_id"];
        
        [defaults setInteger:0 forKey:@"alarm"];
        
        [defaults setInteger:7 forKey:@"sync_day"];
        
        [defaults setValue:@"12:00 AM" forKey:@"sync_time"];
        
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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
