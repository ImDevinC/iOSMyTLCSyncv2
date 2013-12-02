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
