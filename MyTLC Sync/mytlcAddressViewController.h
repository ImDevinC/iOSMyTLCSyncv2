//
//  mytlcAddressViewController.h
//  MyTLC Sync
//
//  Created by Devin Collins on 11/18/13.
//  Copyright (c) 2013 Layer 8 Applications. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface mytlcAddressViewController : UIViewController
@property (weak, nonatomic) IBOutlet UITextField *txtStreet;
@property (weak, nonatomic) IBOutlet UITextField *txtCity;
@property (weak, nonatomic) IBOutlet UITextField *txtState;
@property (weak, nonatomic) IBOutlet UITextField *txtZip;
@property (weak, nonatomic) IBOutlet UITextField *txtStore;
@property (weak, nonatomic) IBOutlet UIButton *btnLookup;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *btnClear;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *actStatus;
@property (weak, nonatomic) IBOutlet UILabel *lblOutput;

@end
