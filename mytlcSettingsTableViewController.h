//
//  mytlcSettingsTableViewController.h
//  MyTLC Sync
//
//  Created by Devin Collins on 11/7/13.
//  Copyright (c) 2013 Layer 8 Applications. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface mytlcSettingsTableViewController : UITableViewController

@property NSMutableDictionary* settings;
@property (strong, nonatomic) IBOutlet UITableView *settingsTable;


@end
