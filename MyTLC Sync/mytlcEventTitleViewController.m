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

#import "mytlcEventTitleViewController.h"

@interface mytlcEventTitleViewController ()

@end

@implementation mytlcEventTitleViewController

@synthesize txtTitle;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void) loadTitle
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    
    NSString* title = [defaults valueForKey:@"title"];
    
    [txtTitle setText:title];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSString* title = [txtTitle text];
    
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults setValue:title forKey:@"title"];
    
    [defaults synchronize];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self loadTitle];
}

@end
