//
//  mytlcCalendarSelectTableViewController.h
//  MyTLC Sync
//
//  Created by Devin Collins on 11/7/13.
//  Copyright (c) 2013 Layer 8 Applications. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface mytlcCalendarSelectTableViewController : UITableViewController

@property (nonatomic, retain) NSMutableArray* calendarList;
@property (strong, nonatomic) IBOutlet UITableView *calendarTable;
@property (nonatomic) NSUInteger selectedCalendar;

@end
