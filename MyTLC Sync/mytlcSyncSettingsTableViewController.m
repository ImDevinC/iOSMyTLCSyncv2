//
//  mytlcSyncSettingsTableViewController.m
//  MyTLC Sync
//
//  Created by Devin Collins on 11/9/13.
//  Copyright (c) 2013 Layer 8 Applications. All rights reserved.
//

#import "mytlcSyncSettingsTableViewController.h"

@interface mytlcSyncSettingsTableViewController ()

@end

@implementation mytlcSyncSettingsTableViewController

@synthesize syncDayTable;
@synthesize timePicker;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void) loadSyncDay
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    
    self.sync_day = [defaults integerForKey:@"sync_day"];
    
    NSUInteger index = 0;

    switch(self.sync_day)
    {
        case 7:
            index = 0;
            break;
        case 8:
            index = 1;
            break;
        default:
            index = self.sync_day + 2;
    }
    
    UITableViewCell* cell = [super tableView:syncDayTable cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
    
    [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
}

- (void) loadSyncTime
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    
    self.sync_time = [defaults stringForKey:@"sync_time"];
    
    NSDateFormatter* df = [[NSDateFormatter alloc] init];
    
    [df setDateFormat:@"h:mm a"];
    
    [timePicker setDate:[df dateFromString:self.sync_time] animated:YES];
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if ([cell accessoryType] == UITableViewCellAccessoryCheckmark)
    {
        return;
    }
    
    switch (indexPath.row)
    {
        case 0:
            self.sync_day = 7;
            break;
        case 1:
            self.sync_day = 8;
            break;
        default:
            self.sync_day = indexPath.row - 2;
            break;
    }
    
    cell = [tableView cellForRowAtIndexPath:indexPath];
    
    [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
    
    for (int i = 0; i < 9; i++) {
        if (i == indexPath.row)
        {
            continue;
        }
        
        cell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
        
        [cell setAccessoryType:UITableViewCellAccessoryNone];
    }
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self loadSyncDay];
    
    [self loadSyncTime];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSDateFormatter* df = [[NSDateFormatter alloc] init];
    
    [df setDateFormat:@"h:mm a"];
    
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults setInteger:self.sync_day forKey:@"sync_day"];
    
    [defaults setValue:[df stringFromDate:[timePicker date]] forKey:@"sync_time"];
    
    [defaults synchronize];
}

@end
