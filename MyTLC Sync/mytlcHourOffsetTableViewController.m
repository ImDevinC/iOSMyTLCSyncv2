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

#import "mytlcHourOffsetTableViewController.h"

@interface mytlcHourOffsetTableViewController ()

@end

@implementation mytlcHourOffsetTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void) loadOffset
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    
    self.offset = [defaults integerForKey:@"hour_offset"];
    
    NSUInteger index = 0;
    
    switch (self.offset)
    {
        case -5:
            index = 0;
            break;
        case -4:
            index = 1;
            break;
        case -3:
            index = 2;
            break;
        case -2:
            index = 3;
            break;
        case -1:
            index = 4;
            break;
        case 0:
            index = 5;
            break;
        case 1:
            index = 6;
            break;
        case 2:
            index = 7;
            break;
        case 3:
            index = 8;
            break;
        case 4:
            index = 9;
            break;
        case 5:
            index = 10;
            break;
        default:
            index = 5;
            break;

    }
    
    UITableViewCell* cell = [super tableView:[super tableView] cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
    
    [cell setAccessoryType:UITableViewCellAccessoryCheckmark];

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
            self.offset = -5;
            break;
        case 1:
            self.offset = -4;
            break;
        case 2:
            self.offset = -3;
            break;
        case 3:
            self.offset = -2;
            break;
        case 4:
            self.offset = -1;
            break;
        case 5:
            self.offset = 0;
            break;
        case 6:
            self.offset = 1;
            break;
        case 7:
            self.offset = 2;
            break;
        case 8:
            self.offset = 3;
            break;
        case 9:
            self.offset = 4;
            break;
        case 10:
            self.offset = 5;
            break;
        default:
            self.offset = 0;
            break;
    }
    
    cell = [tableView cellForRowAtIndexPath:indexPath];
    
    [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
    
    for (int i = 0; i < 11; i++) {
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
    
    [self loadOffset];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults setInteger:self.offset forKey:@"hour_offset"];
    
    [defaults synchronize];
}

@end
