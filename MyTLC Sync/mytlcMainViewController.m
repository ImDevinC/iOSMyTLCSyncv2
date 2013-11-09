//
//  mytlcMainViewController.m
//  MyTLC Sync
//
//  Created by Devin Collins on 10/25/13.
//  Copyright (c) 2013 Layer 8 Applications. All rights reserved.
//

#import "mytlcMainViewController.h"
#import "mytlcCalendarHandler.h"
#import <Security/Security.h>


@interface mytlcMainViewController ()

@end

@implementation mytlcMainViewController

@synthesize btnLogin;
@synthesize txtPassword;
@synthesize txtUsername;
@synthesize aivStatus;
@synthesize lblStatus;
@synthesize chkSave;

mytlcCalendarHandler* ch = nil;

- (void) checkStatus
{
    while (true)
    {
        if (![ch hasNewMessage]){
            continue;
        }
        
        [self performSelectorOnMainThread:@selector(displayMessage) withObject:FALSE waitUntilDone:false];
        
        if ([ch hasCompleted])
        {
            break;
        }
    }
}

- (void) displayAlert:(NSString*) message
{
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"MyTLC Sync" message:message delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil];
    
    [alert show];
}

- (void) displayMessage
{
    [lblStatus setText:[ch getMessage]];
    
    [ch setMessageRead];
    
    if ([ch hasCompleted])
    {
        [aivStatus stopAnimating];
        
        [btnLogin setEnabled:YES];
    }
}

- (IBAction) hideKeyboard
{
    [txtUsername resignFirstResponder];
    [txtPassword resignFirstResponder];
}

- (IBAction)login
{
    NSString* username = [txtUsername text];
    NSString* password = [txtPassword text];
    
    NSDictionary *login = [[NSDictionary alloc] initWithObjectsAndKeys:username, @"username", password, @"password", nil];
    
    [lblStatus setText:@""];
    
    [self hideKeyboard];
    
    if ([username isEqualToString:@""] || [password isEqualToString:@""])
    {
        [self displayAlert:@"Please enter a username and password"];
        
        return;
    }
    
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    
    if ([chkSave isOn]) {
        [defaults setObject:username forKey:@"username"];
        
        [defaults setObject:password forKey:@"password"];
    } else {
        [defaults setObject:nil forKey:@"username"];
        
        [defaults setObject:nil forKey:@"password"];
    }
    
    [defaults synchronize];
    
    [btnLogin setEnabled:NO];
    
    [aivStatus startAnimating];
    
    NSOperationQueue* backgroundQueue = [NSOperationQueue new];
    
    ch = [[mytlcCalendarHandler alloc] init];
    
    NSInvocationOperation* operation = [[NSInvocationOperation alloc] initWithTarget:ch selector:@selector(runEvents:) object:login];
    
    [backgroundQueue addOperation:operation];
    
    operation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(checkStatus) object:nil];
    
    [backgroundQueue addOperation:operation];
}

- (BOOL) textFieldShouldReturn:(UITextField*) textField
{
    if ([textField isEqual:txtUsername])
    {
        [textField resignFirstResponder];
        [txtPassword becomeFirstResponder];
        return NO;
    } else {
        [textField resignFirstResponder];
        [self login];
        return NO;
    }
    
    return YES;
}

- (IBAction)unwindToMain:(UIStoryboardSegue *)segue
{
    
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    UIGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];
    
    [self.view addGestureRecognizer:tap];
    
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    
    BOOL firstRun = ![defaults boolForKey:@"firstRun"];
    
    if (firstRun) {
        [defaults setBool:YES forKey:@"firstRun"];
        
        [defaults setValue:@"default" forKey:@"calendar_id"];
        
        [defaults setInteger:0 forKey:@"alarm"];
        
        [defaults setInteger:0 forKey:@"sync_day"];
        
        [defaults setValue:@"12:00 AM" forKey:@"sync_time"];
        
        [defaults synchronize];
    } else {
        NSString* username = [defaults objectForKey:@"username"];
        
        NSString* password = [defaults objectForKey:@"password"];
        
        if (username != nil && password != nil) {
            [txtUsername setText:username];
            
            [txtPassword setText:password];
            
            [chkSave setOn:YES];
        } else {
            [chkSave setOn:NO];
        }
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
