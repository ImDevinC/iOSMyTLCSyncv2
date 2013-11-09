//
//  mytlcAlarmTableViewController.m
//  MyTLC Sync
//
//  Created by Devin Collins on 11/8/13.
//  Copyright (c) 2013 Layer 8 Applications. All rights reserved.
//

#import "mytlcAlarmTableViewController.h"

@interface mytlcAlarmTableViewController ()

@end

@implementation mytlcAlarmTableViewController

@synthesize alarmTable;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self loadSavedAlarm];
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
            self.alarm = 0;
            break;
        case 1:
            self.alarm = 5;
            break;
        case 2:
            self.alarm = 15;
            break;
        case 3:
            self.alarm = 30;
            break;
        case 4:
            self.alarm = 60;
            break;
        case 5:
            self.alarm = 120;
            break;
        case 6:
            self.alarm = 180;
            break;
    }
    
    cell = [tableView cellForRowAtIndexPath:indexPath];
    
    [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
    
    for (int i = 0; i < 7; i++) {
        if (i == indexPath.row)
        {
            continue;
        }
        
        cell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
        
        [cell setAccessoryType:UITableViewCellAccessoryNone];
    }
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) loadSavedAlarm
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    
    self.alarm = [defaults integerForKey:@"alarm"];
    
    NSUInteger index = 0;
    
    switch(self.alarm)
    {
        case 0:
            index = 0;
            break;
        case 5:
            index = 1;
            break;
        case 15:
            index = 2;
            break;
        case 30:
            index = 3;
            break;
        case 60:
            index = 4;
            break;
        case 120:
            index = 5;
            break;
        case 180:
            index = 6;
            break;
        default:
            index = 0;
    }
    
    UITableViewCell* cell = [super tableView:alarmTable cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
    
    [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults setInteger:self.alarm forKey:@"alarm"];
    
    [defaults synchronize];
}

@end
