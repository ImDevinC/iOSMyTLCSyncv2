//
//  mytlcSyncSettingsTableViewController.h
//  MyTLC Sync
//
//  Created by Devin Collins on 11/9/13.
//  Copyright (c) 2013 Layer 8 Applications. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface mytlcSyncSettingsTableViewController : UITableViewController

@property (strong, nonatomic) IBOutlet UITableView *syncDayTable;
@property (weak, nonatomic) IBOutlet UIDatePicker *timePicker;
@property int sync_day;
@property NSString* sync_time;

@end
