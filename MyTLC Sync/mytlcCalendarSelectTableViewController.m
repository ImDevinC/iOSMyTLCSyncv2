//
//  mytlcCalendarSelectTableViewController.m
//  MyTLC Sync
//
//  Created by Devin Collins on 11/7/13.
//  Copyright (c) 2013 Layer 8 Applications. All rights reserved.
//

#import "mytlcCalendarSelectTableViewController.h"
#import "mytlcSettingsTableViewController.h"
#import <EventKit/EventKit.h>

@interface mytlcCalendarSelectTableViewController ()

@end

@implementation mytlcCalendarSelectTableViewController

@synthesize calendarTable;

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
    
    [self loadCalendars];
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

- (void) loadCalendars
{
    self.calendarList = [[NSMutableArray alloc] init];
    
    NSMutableDictionary* dictionary = [[NSMutableDictionary alloc] init];
    
    [dictionary setObject:@"Default Calendar" forKey:@"title"];
    
    [dictionary setObject:@"default" forKey:@"value"];
    
    [self.calendarList addObject:dictionary];
    
    EKEventStore* eventStore = [[EKEventStore alloc] init];
    
    self.selectedCalendar = 0;
    
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    
    NSString* savedCalendar = [defaults objectForKey:@"calendar_id"];
    
    for (EKCalendar* calendar in [eventStore calendarsForEntityType:nil])
    {
        dictionary = [[NSMutableDictionary alloc] init];
        
        [dictionary setObject:[calendar title] forKey:@"title"];
        
        [dictionary setObject:[calendar calendarIdentifier] forKey:@"value"];
        
        [self.calendarList addObject:dictionary];
        
        if ([[calendar calendarIdentifier] isEqualToString:savedCalendar])
        {
            self.selectedCalendar = [self.calendarList count] - 1;
        }
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self checkCalendarPermissions];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if ([cell accessoryType] == UITableViewCellAccessoryCheckmark)
    {
        return;
    }
    
    self.selectedCalendar = indexPath.row;
    
    cell = [tableView cellForRowAtIndexPath:indexPath];
    
    [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
    
    for (int i = 0; i < self.calendarList.count; i++) {
        if (i == indexPath.row)
        {
            continue;
        }
        
        cell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
        
        [cell setAccessoryType:UITableViewCellAccessoryNone];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.calendarList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    NSDictionary* calendar = [self.calendarList objectAtIndex:indexPath.row];
    
    NSString* title = [calendar objectForKey:@"title"];
    
    [cell.textLabel setText:title];
    
    if (indexPath.row == self.selectedCalendar)
    {
        [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
    } else {
        [cell setAccessoryType:UITableViewCellAccessoryNone];
    }
    
    return cell;
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    
    NSDictionary* calendar = self.calendarList[self.selectedCalendar];
    
    [defaults setObject:[calendar objectForKey:@"value"] forKey:@"calendar_id"];
    
    [defaults synchronize];
}

@end
