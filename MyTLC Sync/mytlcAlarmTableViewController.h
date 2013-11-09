//
//  mytlcAlarmTableViewController.h
//  MyTLC Sync
//
//  Created by Devin Collins on 11/8/13.
//  Copyright (c) 2013 Layer 8 Applications. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface mytlcAlarmTableViewController : UITableViewController

@property int alarm;
@property (strong, nonatomic) IBOutlet UITableView *alarmTable;

@end
