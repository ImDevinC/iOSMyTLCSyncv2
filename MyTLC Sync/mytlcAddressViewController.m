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

#import "mytlcAddressViewController.h"

@interface mytlcAddressViewController ()

@end

@implementation mytlcAddressViewController

@synthesize btnClear;
@synthesize btnLookup;
@synthesize txtCity;
@synthesize txtState;
@synthesize txtStore;
@synthesize txtStreet;
@synthesize txtZip;
@synthesize lblOutput;
@synthesize actStatus;

- (IBAction)clear:(id)sender
{
    [txtCity setText:@""];
    [txtState setText:@""];
    [txtStore setText:@""];
    [txtStreet setText:@""];
    [txtZip setText:@""];
    [lblOutput setText:@""];
}

- (IBAction) hideKeyboard
{
    [txtCity resignFirstResponder];
    [txtState resignFirstResponder];
    [txtStore resignFirstResponder];
    [txtStreet resignFirstResponder];
    [txtZip resignFirstResponder];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void) findAddressForStore:(NSString*)storeId
{
    [actStatus startAnimating];
    
    [btnLookup setEnabled:NO];
    
    [btnClear setEnabled:NO];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://api.remix.bestbuy.com/v1/stores(storeId=%@)?apiKey=%@&format=json&show=address,city,postalCode,region,storeId", storeId, @"yuptvvgha79f4xw4nvntbcpv"]]];
        
        NSError *err;

        NSData *response = [NSURLConnection sendSynchronousRequest:urlRequest
                                                 returningResponse:nil error:&err];
        
        if (err)
        {
            dispatch_sync(dispatch_get_main_queue(), ^{
                [lblOutput setText:@"Unable to get store information"];
           
                [actStatus stopAnimating];
           
                [btnLookup setEnabled:YES];
           
                [btnClear setEnabled:YES];
            });
            
            return;
        }
        
        err = nil;
        
        NSDictionary *storeInfo = [NSJSONSerialization JSONObjectWithData:response options:0 error:&err];
        
        if (err)
        {
            dispatch_sync(dispatch_get_main_queue(), ^{
                [lblOutput setText:@"Unable to get store information"];
                
                [actStatus stopAnimating];
                
                [btnLookup setEnabled:YES];
                
                [btnClear setEnabled:YES];
            });
            
            return;
        }
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            NSArray* store = [storeInfo objectForKey:@"stores"];

            if (!store || [store count] == 0)
            {
                [lblOutput setText:@"Couldn't find store number"];
                
                [actStatus stopAnimating];
                
                [btnLookup setEnabled:YES];
                
                [btnClear setEnabled:YES];
                
                return;
            }
            
            NSString* address = [[NSString alloc] initWithFormat:@"%@", [store valueForKey:@"address"]];
            
            NSString* city = [[NSString alloc] initWithFormat:@"%@", [store valueForKey:@"city"]];
            
            NSString* zip = [[NSString alloc] initWithFormat:@"%@", [store valueForKey:@"postalCode"]];
            
            NSString* state = [[NSString alloc] initWithFormat:@"%@", [store valueForKey:@"region"]];
            
            NSCharacterSet* replace = [NSCharacterSet characterSetWithCharactersInString:@"( )"];
            
            address = [address stringByTrimmingCharactersInSet:replace];
            
            city = [city stringByTrimmingCharactersInSet:replace];
            
            state = [state stringByTrimmingCharactersInSet:replace];
            
            zip = [zip stringByTrimmingCharactersInSet:replace];
            
            replace = [NSCharacterSet whitespaceAndNewlineCharacterSet];
            
            address = [address stringByTrimmingCharactersInSet:replace];
            
            city = [city stringByTrimmingCharactersInSet:replace];
            
            state = [state stringByTrimmingCharactersInSet:replace];
            
            zip = [zip stringByTrimmingCharactersInSet:replace];
            
            replace = [NSCharacterSet characterSetWithCharactersInString:@"\""];
            
            address = [address stringByTrimmingCharactersInSet:replace];
            
            city = [city stringByTrimmingCharactersInSet:replace];
            
            state = [state stringByTrimmingCharactersInSet:replace];
            
            zip = [zip stringByTrimmingCharactersInSet:replace];
            
            [self.txtStreet setText:address];

            [self.txtCity setText:city];

            [self.txtState setText:state];

            [self.txtZip setText:zip];
            
            [self.actStatus stopAnimating];
            
            [btnClear setEnabled:YES];
            
            [btnLookup setEnabled:YES];
        });
    });
}

- (void) fillInTheBlanks:(NSDictionary*)store
{

}

- (void) loadAddress
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    
    [txtStreet setText:[defaults valueForKey:@"address-street"]];
    
    [txtCity setText:[defaults valueForKey:@"address-city"]];
    
    [txtState setText:[defaults valueForKey:@"address-state"]];
    
    [txtZip setText:[defaults valueForKey:@"address-zip"]];
}

- (IBAction)lookup:(id)sender
{
    NSString* store = [txtStore text];
    
    if ([store length] == 0)
    {
        return;
    }
    
    [self findAddressForStore:store];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSString* city = [txtCity text];
    NSString* state = [txtState text];
    NSString* street = [txtStreet text];
    NSString* zip = [txtZip text];
    
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    
    if (([city length] == 0) || ([state length] != 2) || ([street length] == 0))
    {
        [defaults removeObjectForKey:@"address-city"];
        [defaults removeObjectForKey:@"address-state"];
        [defaults removeObjectForKey:@"address-street"];
        [defaults removeObjectForKey:@"address-zip"];
    } else {
        [defaults setValue:city forKey:@"address-city"];
        [defaults setValue:state forKey:@"address-state"];
        [defaults setValue:street forKey:@"address-street"];
        [defaults setValue:zip forKey:@"address-zip"];
    }
    
    [defaults synchronize];
}

- (BOOL) textFieldShouldReturn:(UITextField*) textField
{
    if ([textField isEqual:txtStreet])
    {
        [textField resignFirstResponder];
        [txtCity becomeFirstResponder];
        return NO;
    } else if ([textField isEqual:txtCity]) {
        [textField resignFirstResponder];
        [txtState becomeFirstResponder];
        return NO;
    } else if ([textField isEqual:txtState]) {
        [textField resignFirstResponder];
        [txtZip becomeFirstResponder];
        return NO;
    } else if ([textField isEqual:txtZip]) {
        [textField resignFirstResponder];
        return YES;
    } else if ([textField isEqual:txtStore]) {
        [textField resignFirstResponder];
        // TODO: Perform lookup
        return NO;
    }
    
    return YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    UIGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];
    
    [self.view addGestureRecognizer:tap];
    
    [self loadAddress];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
