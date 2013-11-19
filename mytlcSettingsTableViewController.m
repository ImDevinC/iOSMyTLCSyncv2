//
//  mytlcSettingsTableViewController.m
//  MyTLC Sync
//
//  Created by Devin Collins on 11/7/13.
//  Copyright (c) 2013 Layer 8 Applications. All rights reserved.
//

#import "mytlcSettingsTableViewController.h"
#import <EventKit/EventKit.h>

@interface mytlcSettingsTableViewController ()

@end

@implementation mytlcSettingsTableViewController

@synthesize settingsTable;

- (void) checkCalendarPermissions
{
    EKEventStore* eventStore = [[EKEventStore alloc] init];
    
    if ([eventStore respondsToSelector:@selector(requestAccessToEntityType:completion:)])
    {
        [eventStore requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError* err) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (err || !granted)
                {
                    [self displayAlert:@"Please check your calendar permissions to verify MyTLC Sync has access to your calendar"];
                }
            });
        }];
    }
    
    [self loadDefaultCalendar];
}

- (void) loadDefaultCalendar
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    
    UITableViewCell* calendar_cell = [super tableView:settingsTable cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    
    NSString* calendar_id = [defaults objectForKey:@"calendar_id"];
    
    if ([calendar_id isEqualToString:@"default"])
    {
        [calendar_cell.textLabel setText:@"Default Calendar"];
    }
    else
    {
        EKEventStore* eventStore = [[EKEventStore alloc] init];
        
        EKCalendar* calendar = [eventStore calendarWithIdentifier:calendar_id];
        
        [calendar_cell.textLabel setText:[calendar title]];
    }
}

- (void) loadAddress
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    
    NSString* street = [defaults valueForKey:@"address-street"];
    
    NSString* city = [defaults valueForKey:@"address-city"];
    
    NSString* state = [defaults valueForKey:@"address-state"];
    
    NSString* zip = [defaults valueForKey:@"address-zip"];
    
    NSString* address = @"None";
    
    if ([street length] > 0 && [city length] > 0 && [state length] > 0)
    {
        address = [[NSString alloc] initWithFormat:@"%@ %@, %@", [defaults valueForKey:@"address-street"], [defaults valueForKey:@"address-city"], [defaults valueForKey:@"address-state"]];
        
        if ([zip length] > 0)
        {
            address = [NSString stringWithFormat:@"%@ %@", address, zip];
        }
    }
        
    UITableViewCell* alarm_cell = [super tableView:settingsTable cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:4]];
    
    [alarm_cell.textLabel setText:address];
}

- (void) loadAlarmSettings
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    
    NSUInteger alarm = [defaults integerForKey:@"alarm"];
    
    NSString* display = [[NSString alloc] init];
    
    switch(alarm)
    {
        case 0:
            display = @"None";
            break;
        case 5:
            display = @"5 Minutes Before";
            break;
        case 15:
            display = @"15 Minutes Before";
            break;
        case 30:
            display = @"30 Minutes Before";
            break;
        case 60:
            display = @"1 Hour Before";
            break;
        case 120:
            display = @"2 Hours Before";
            break;
        case 180:
            display = @"3 Hours Before";
            break;
        default:
            display = @"None";
    }
    
    UITableViewCell* alarm_cell = [super tableView:settingsTable cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]];
    
    [alarm_cell.textLabel setText:display];
}

- (void) loadOffsetSettings
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    
    NSUInteger offset = [defaults integerForKey:@"hour_offset"];

    NSString* display = [[NSString alloc] init];
    
    switch (offset)
    {
        case -5:
            display = @"-5 Hours";
            break;
        case -4:
            display = @"-4 Hours";
            break;
        case -3:
            display = @"-3 Hours";
            break;
        case -2:
            display = @"-2 Hours";
            break;
        case -1:
            display = @"-1 Hour";
            break;
        case 0:
            display = @"None";
            break;
        case 1:
            display = @"1 Hour";
            break;
        case 2:
            display = @"2 Hours";
            break;
        case 3:
            display = @"3 Hours";
            break;
        case 4:
            display = @"4 Hours";
            break;
        case 5:
            display = @"5 Hours";
            break;
    }
    
    UITableViewCell* alarm_cell = [super tableView:settingsTable cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:3]];
    
    [alarm_cell.textLabel setText:display];
}

- (void) loadSavedSettings
{
    [self checkCalendarPermissions];
    
    [self loadAlarmSettings];
    
    [self loadSyncSettings];
    
    [self loadOffsetSettings];
    
    [self loadAddress];
}

- (void) loadSyncSettings
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    
    NSUInteger alarm = [defaults integerForKey:@"sync_day"];
    
    NSString* time = [defaults valueForKey:@"sync_time"];
    
    NSString* display = [[NSString alloc] init];
    
    switch(alarm)
    {
        case 0:
            display = @"Sunday";
            break;
        case 1:
            display = @"Monday";
            break;
        case 2:
            display = @"Tuesday";
            break;
        case 3:
            display = @"Wednesday";
            break;
        case 4:
            display = @"Thursday";
            break;
        case 5:
            display = @"Friday";
            break;
        case 6:
            display = @"Saturday";
            break;
        case 7:
            display = @"Never";
            break;
        case 8:
            display = @"Every Day";
            break;
        default:
            display = @"Never";
    }
    
    if (alarm != 7)
    {
        display = [display stringByAppendingString:[NSString stringWithFormat:@" @ %@", time]];
    }
    
    UITableViewCell* alarm_cell = [super tableView:settingsTable cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:2]];
    
    [alarm_cell.textLabel setText:display];
}

- (void) displayAlert:(NSString*) message
{
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"MyTLC Sync" message:message delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil];
    
    [alert show];
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (IBAction)unwindToSettings:(UIStoryboardSegue *)segue
{
    [self loadSavedSettings];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self loadSavedSettings];
    
    [self loadSyncSettings];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
