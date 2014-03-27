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

#import "mytlcCalendarHandler.h"
#import "mytlcShift.h"
#import <EventKit/EventKit.h>

@implementation mytlcCalendarHandler

BOOL done = NO;
BOOL newMessageExists = NO;
EKEventStore* eventStore = nil;
NSString* message = nil;
NSMutableArray* g_cookies;

- (void) checkCalendarAccess:(NSMutableArray*) shifts
{
    eventStore = [[EKEventStore alloc] init];
    
    if ([eventStore respondsToSelector:@selector(requestAccessToEntityType:completion:)])
    {
        [eventStore requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError* err) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (err || !granted)
                {
                    [self updateProgress:@"Couldn't get access to the calendar, please check calendar permissions in your settings"];
                    
                    done = YES;
                }
                else
                {
                    [self updateProgress:@"Deleting old entries"];
                    NSMutableArray* shiftsToAdd = [self removeDuplicatesFromShifts:shifts];
                    
                    [self updateProgress:@"Adding shifts to calendar"];

                    [self createCalendarEntries:shiftsToAdd];
                }
            });
        }];
    }
}

- (NSMutableArray*) removeDuplicatesFromShifts:(NSMutableArray*) newShifts
{
    NSCalendar* cal = [NSCalendar currentCalendar];
    
    NSDate* date = [NSDate date];
    
    NSDateComponents* components = [cal components:(NSMonthCalendarUnit | NSYearCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit) fromDate:date];
    
    [components setHour:0];
    
    [components setMinute:0];
    
    [components setSecond:0];
    
    NSDate* startDate = [cal dateFromComponents:components];
    
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    
    NSMutableArray* shifts = [NSMutableArray arrayWithArray:[defaults arrayForKey:@"shifts"]];
    
    if ([shifts count] == 0)
    {
        return newShifts;
    }
    
    for (long x = shifts.count - 1; x >= 0; x--)
    {
        EKEvent* event = [eventStore eventWithIdentifier:shifts[x]];
        
        if ([event endDate] == [startDate earlierDate:[event endDate]])
        {
            [shifts removeObjectAtIndex:x];
            continue;
        }
        
        BOOL shiftFound = NO;
        
        for (long y = newShifts.count - 1; y >= 0; y--)
        {
            if ([[event startDate] isEqualToDate:[newShifts[y] startDate]] && [[event endDate] isEqualToDate:[newShifts[y] endDate]])
            {
                shiftFound = YES;
                [newShifts removeObjectAtIndex:y];
            }
        }
        
        if (shiftFound == NO)
        {
            NSError* err;
            [eventStore removeEvent:event span:EKSpanThisEvent error:&err];
            [shifts removeObjectAtIndex:x];
        }
    }
    
    [defaults setObject:shifts forKey:@"shifts"];
    
    [defaults synchronize];
    
    return newShifts;
}
                           
- (void) createCalendarEntries:(NSMutableArray*) shifts
{
    int count = 0;
    
    NSString* calendar_id = [self getSelectedCalendarId];
    
    NSInteger alarm_time = -1 * ([self getAlarmSettings] * 60);
    
    NSString* address = [self getAddress];
    
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    
    NSMutableArray* saveShifts = [[NSMutableArray alloc] initWithArray:[defaults arrayForKey:@"shifts"]];
    
    NSString* title = [self getTitle];
    
    for (mytlcShift* shift in shifts)
    {
        EKEvent* event = [EKEvent eventWithEventStore:eventStore];
        
        event.notes = shift.department;
        
        event.title = title;
        
        event.startDate = shift.startDate;
        
        event.endDate = shift.endDate;
        
        if (alarm_time != 0)
        {
            EKAlarm* alarm = [EKAlarm alarmWithRelativeOffset:alarm_time];
            
            event.alarms = [NSArray arrayWithObject:alarm];
        }
        
        if ([address length] > 0)
        {
            event.location = address;
        }
        
        [event setCalendar:[eventStore calendarWithIdentifier:calendar_id]];
        
        NSError *err = nil;
        
        [eventStore saveEvent:event span:EKSpanThisEvent error:&err];
        
        if (!err)
        {
            [saveShifts addObject:[event eventIdentifier]];
            
            count++;
        }

    }
    
    [defaults setObject:saveShifts forKey:@"shifts"];
    
    [defaults synchronize];
    
    [self getData:@"https://mytlc.bestbuy.com/etm/etmMenu.jsp?pageAction=logout"];
    
    done = YES;
    
    [self updateProgress:[NSString stringWithFormat:@"Added %d shifts to your calendar", count]];
}

- (NSString*) createParams:(NSMutableDictionary*) dictionary
{
    NSString* result = nil;
    
    for (NSString* key in dictionary)
    {
        result = [NSString stringWithFormat:@"%@&%@=%@", result, key, [dictionary objectForKey:key]];
    }
    
    return result;
}

- (NSString*) getAddress
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    
    NSString* address = [[NSString alloc] initWithFormat:@"%@ %@, %@ %@", [defaults valueForKey:@"address-street"], [defaults valueForKey:@"address-city"], [defaults valueForKey:@"address-state"], [defaults valueForKey:@"address-zip"]];
    
    if ([address isEqualToString:@"(null) (null), (null) (null)"])
    {
        return @"";
    }
    
    return address;
}

- (NSUInteger) getAlarmSettings
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];

    return [defaults integerForKey:@"alarm"];
}

- (NSString*) getTitle
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    
    return [defaults stringForKey:@"title"];
}

- (NSString*) getData:(NSString*) url
{
//    NSURL* urlRequest = [NSURL URLWithString:url];
//
//    NSError* err = nil;
//    
//    NSString* result = [NSString stringWithContentsOfURL:urlRequest encoding:NSUTF8StringEncoding error:&err];
//
//    if (err)
//    {
//        return nil;
//    }
//    
//    return result;
    
    NSURL* urlRequest = [NSURL URLWithString:url];
    
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[urlRequest standardizedURL]];
    
    NSError* err = nil;
    
    NSData* responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:&err];
    
    if ([g_cookies count] == 0) {
        for (NSHTTPCookie* nsCookie in [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies])
        {
            [g_cookies addObject:nsCookie];
        }
    }
    
    if (!err) {
        return [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];;
    }
    
    return nil;

}

- (NSString*) getMessage
{
    return message;
}

- (NSInteger) getOffsetSettings
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    
    NSInteger offset = [defaults integerForKey:@"hour_offset"] * 60 * 60;
    
    return offset;
}

- (NSString*) getSelectedCalendarId
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    
    NSString* calendar_id = [defaults objectForKey:@"calendar_id"];
    
    if (calendar_id == nil || [calendar_id isEqualToString:@"default"])
    {
        return [[eventStore defaultCalendarForNewEvents] calendarIdentifier];
    }
    
    return calendar_id;
}

- (BOOL) hasCompleted
{
    return done;
}

- (BOOL) hasNewMessage
{
    return newMessageExists;
}

- (BOOL) isTLCActive:(NSString*) data
{
    if ([[data lowercaseString] rangeOfString:@"/etm/time/timesheet/etmtnsmonth.jsp"].location == NSNotFound)
    {
        return FALSE;
    }
    
    return TRUE;
}

- (NSMutableArray*) parseSchedule:(NSString*) data
{
    if ([[data lowercaseString] rangeOfString:@"calmonthtitle"].location == NSNotFound)
    {
        return nil;
    }
    
    NSRange begin = [[data lowercaseString] rangeOfString:@"calmonthtitle"];
    
    NSString* sMonth = [data substringFromIndex:begin.location + 15];
    
    NSRange end = [[sMonth lowercaseString] rangeOfString:@"</span>"];
    
    sMonth = [sMonth substringToIndex:end.location];
    
    if ([[data lowercaseString] rangeOfString:@"calyeartitle"].location == NSNotFound)
    {
        return nil;
    }
    
    begin = [[data lowercaseString] rangeOfString:@"calyeartitle"];
    
    NSString* sYear = [data substringFromIndex:begin.location + 14];
    
    end = [[sYear lowercaseString] rangeOfString:@"</span>"];
    
    sYear = [sYear substringToIndex:end.location];
    
    if ([[data lowercaseString] rangeOfString:@"calweekdayheader"].location == NSNotFound)
    {
        return nil;
    }
    
    data = [data substringFromIndex:[[data lowercaseString] rangeOfString:@"calweekdayheader"].location];
    
    if ([[data lowercaseString] rangeOfString:@"document.forms[0].new_month_year"].location == NSNotFound)
    {
        return nil;
    }
    
    data = [data substringToIndex:[[data lowercaseString] rangeOfString:@"document.forms[0].new_month_year"].location];
    
    if (!data)
    {
        return nil;
    }
    
    NSArray* schedules = [data componentsSeparatedByString:@"</tr>"];
    
    
    if (!schedules)
    {
        return nil;
    }
    
    NSMutableArray* workDays = [NSMutableArray array];

    for (NSString* schedule in schedules)
    {
        if ([[schedule lowercaseString] rangeOfString:@"off"].location != NSNotFound)
        {
            continue;
        }
        
        if ([[schedule lowercaseString] rangeOfString:@"calendarcellregularcurrent"].location == NSNotFound && [[schedule lowercaseString] rangeOfString:@"calendarcellregularfuture"].location == NSNotFound)
        {
            continue;
        }
        
        NSString* date = nil;
        
        if ([[schedule lowercaseString] rangeOfString:@"calendarcellregularcurrent"].location == NSNotFound)
        {
            begin = [[schedule lowercaseString] rangeOfString:@"calendardatenormal"];
            
            date = [schedule substringFromIndex:begin.location + 22];
        } else {
            begin = [[schedule lowercaseString] rangeOfString:@"calendardatecurrent"];
            
            date = [schedule substringFromIndex:begin.location + 23];
        }
        
        if (!date)
        {
            continue;
        }
        
        end = [[date lowercaseString] rangeOfString:@"</span>"];
        
        date = [date substringToIndex:end.location];
        
        NSCharacterSet* replace = [NSCharacterSet whitespaceAndNewlineCharacterSet];
        
        date = [date stringByTrimmingCharactersInSet:replace];
        
        NSArray* shifts = [[schedule lowercaseString] componentsSeparatedByString:@"<br>"];
        
        NSInteger offset = [self getOffsetSettings];
        
        for (int i = 0; i < [shifts count]; i++)
        {
            if (([[shifts[i] lowercaseString] rangeOfString:@"am"].location != NSNotFound && [[shifts[i] lowercaseString] rangeOfString:@"<td>"].location == NSNotFound) || ([[shifts[i] lowercaseString] rangeOfString:@"pm"].location != NSNotFound && [[shifts[i] lowercaseString] rangeOfString:@"<td>"].location == NSNotFound))
            {
                NSString* dept = @"";
                
                if (i != shifts.count - 1)
                {
                    if ([[shifts[i + 1] lowercaseString] rangeOfString:@"l-"].location != NSNotFound)
                    {
                        dept = [shifts[i + 1] stringByTrimmingCharactersInSet:replace];
                    }
                }
                
                mytlcShift* shift = [[mytlcShift alloc] init];
                
                shift.department = dept;
            
                NSRange split = [shifts[i] rangeOfString:@" - "];
                
                NSString* time = [shifts[i] substringToIndex:split.location];
                
                shift.startDate = [self parseTime:[NSString stringWithFormat:@"%@ %@, %@ %@", sMonth, date, sYear, time]];
                
                shift.startDate = [shift.startDate dateByAddingTimeInterval:offset];
                
                time = [shifts[i] substringFromIndex:split.location + 3];
                
                shift.endDate = [self parseTime:[NSString stringWithFormat:@"%@ %@, %@ %@", sMonth, date, sYear, time]];
                
                shift.endDate = [shift.endDate dateByAddingTimeInterval:offset];
                
                if (shift.endDate == [shift.endDate earlierDate:shift.startDate])
                {
                    shift.endDate = [shift.endDate dateByAddingTimeInterval:60 * 60 * 24];
                }
                
                [workDays addObject:shift];
            }
        }
    }
    
    return workDays;
}

- (NSDate*) parseTime:(NSString*) time
{
    NSDateFormatter* df = [[NSDateFormatter alloc] init];
    
    [df setDateFormat:@"MMMM dd, yyyy hh:mm a"];
    
    NSDate* date = [df dateFromString:time];
    
    return date;
}

- (NSString*) parseToken:(NSString*) data
{
    if ([[data lowercaseString]rangeOfString:@"end hotkey for submit"].location == NSNotFound)
    {
        return nil;
    }
    
    NSRange end = [[data lowercaseString] rangeOfString:@"end hotkey for submit"];
    
    data = [data substringFromIndex:end.location];
    
    if (([[data lowercaseString] rangeOfString:@"hidden"].location == NSNotFound) || ([[data lowercaseString] rangeOfString:@"url_login_token"].location == NSNotFound))
        {
            return nil;
        }
    
    NSRange begin = [[data lowercaseString] rangeOfString:@"hidden"];
    
    data = [data substringFromIndex:begin.location + 14];
    
    end = [[data lowercaseString] rangeOfString:@"url_login_token"];
    
    data = [data substringToIndex:end.location - 7];
    
    return data;
}

- (NSString*) parseToken2:(NSString*) data
{
    if ([[data lowercaseString] rangeOfString:@"securetoken"].location == NSNotFound)
    {
        return nil;
    }
    
    NSRange begin = [[data lowercaseString] rangeOfString:@"securetoken"];
    
    data = [data substringFromIndex:begin.location + 20];
    
    if ([data rangeOfString:@"'/>"].location == NSNotFound)
    {
        return nil;
    }
    
    NSRange end = [data rangeOfString:@"'/>"];
    
    data = [data substringToIndex:end.location];
    
    return data;
}

- (NSString*) parseWbat:(NSString*) data
{
    if ([[data lowercaseString] rangeOfString:@"wbat"].location == NSNotFound)
    {
        return nil;
    }
    
    NSRange begin = [[data lowercaseString] rangeOfString:@"wbat"];
    
    data = [data substringFromIndex:begin.location + 23];
    
    if ([data rangeOfString:@"'>"].location == NSNotFound)
    {
        return nil;
    }
    
    NSRange end = [data rangeOfString:@"'>"];
    
    data = [data substringToIndex:end.location];
    
    return data;
}

- (NSString*) postData:(NSString*) url params:(NSString*) params
{
    NSURL* urlRequest = [NSURL URLWithString:url];
    
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[urlRequest standardizedURL]];

    NSDictionary* headers = [NSHTTPCookie requestHeaderFieldsWithCookies:g_cookies];
    
    [request setAllHTTPHeaderFields:headers];
    
    [request setHTTPMethod:@"POST"];
    
    [request setValue:@"application/x-www-form-urlencoded;charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    
    [request setHTTPBody:[params dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSError* err = nil;
    
    NSData* responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:&err];

    if (!err) {
        return [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];;
    }
    
    return nil;
}

- (BOOL) runEvents:(NSDictionary*)login
{
    done = NO;
    
    [self updateProgress:@"Checking for calendar access"];
    
    EKEventStore* eventStore = [[EKEventStore alloc] init];
    
    if (![eventStore respondsToSelector:@selector(requestAccessToEntityType:completion:)])
    {
        [eventStore requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
            });
        }];
    }
    
    [self updateProgress:@"Getting login credentials"];
    
    NSString* params = nil;

    NSString* loginToken = nil;

    NSString* wbat = nil;
    
    NSString* username = [login valueForKey:@"username"];
    
    NSString* password = [login valueForKey:@"password"];
    
    [self updateProgress:@"Checking for network connection"];
    
    NSString* data = [self getData:@"https://mytlc.bestbuy.com/etm/login.jsp"];
    
    if (!data) {
        [self updateProgress:@"Error connecting to MyTLC, do you have a network connection?"];
        
        done = YES;
        
        return NO;
    }
    
    [self updateProgress:@"Getting login token"];
    
    loginToken = [self parseToken:data];
    
    wbat = [self parseWbat:data];
    
    if (!loginToken)
    {
        [self updateProgress:@"Couldn't get login token, do you have a valid network connection?"];
        
        done = YES;
        
        return NO;
    }
    
    params = [self createParams:[NSMutableDictionary dictionaryWithObjectsAndKeys:@"login", @"pageAction", loginToken, @"url_login_token", wbat, @"wbat", username, @"login", password, @"password", @"DEFAULT", @"client", @"false", @"localeSelected", @"", @"STATUS_MESSAGE_HIDDEN", @"0", @"wbXpos", @"0", @"wbYpos" , nil]];
    
    if (!params)
    {
        [self updateProgress:@"Couldn't create logon credentials, please try again"];
        
        return NO;
    }
    
    [self updateProgress:@"Logging in..."];
    
    data = [self postData:@"https://mytlc.bestbuy.com/etm/login.jsp" params:params];
    
    if ([[data lowercaseString] rangeOfString:@"etmmenu.jsp"].location == NSNotFound)
    {
        [self updateProgress:@"Incorrect username and password, please try again"];
        
        done = YES;
        
        return NO;
    }
    
//    if (![self isTLCActive:data])
//    {
//        [self updateProgress:@"MyTLC is currently undergoing maintenance, please try again later"];
//        
//        done = YES;
//        
//        return NO;
//    }
    
    [self updateProgress:@"Getting schedule"];
    
    data = [self getData:@"https://mytlc.bestbuy.com/etm/time/timesheet/etmTnsMonth.jsp"];
    
    if (!data)
    {
        [self updateProgress:@"Couldn't get schedule, please try again later"];
        
        done = YES;
        
        return NO;
    }
    
    [self updateProgress:@"Parsing shifts"];
    
    NSMutableArray* shifts = [self parseSchedule:data];
    
    [self updateProgress:@"Getting next security token"];
    
    NSString* securityToken = [self parseToken2:data];
    
    wbat = [self parseWbat:data];
    
    if (!securityToken && !wbat)
    {
        [self updateProgress:@"Couldn't get security token, please try logging in again"];
        
        done = YES;
        
        return NO;
    }
    
    [self updateProgress:@"Formatting shifts"];
    
    NSCalendar* calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    
    NSDateComponents* dateComponents = [calendar components:(NSMonthCalendarUnit | NSDayCalendarUnit | NSYearCalendarUnit) fromDate:[NSDate date]];
    
    NSString* month = [NSString stringWithFormat:@"%lD", [dateComponents month] + 1];
    
    NSString* year = [NSString stringWithFormat:@"%lD", (long) [dateComponents year]];
    
    if ([month isEqualToString:@"13"])
    {
        month = @"01";
        
        year = [NSString stringWithFormat:@"%lD", [dateComponents year] + 1];
    } else if ([month length] == 1) {
        month = [NSString stringWithFormat:@"0%@", month];
    }
    
    NSString* date = [NSString stringWithFormat:@"%@/%@", month, year];
    
    [self updateProgress:@"Creating parameters for second schedule"];
    
    params = [self createParams:[NSMutableDictionary dictionaryWithObjectsAndKeys:@"", @"pageAction", date, @"NEW_MONTH_YEAR", securityToken, @"secureToken", wbat, @"wbat", @"11", @"selectedTocId", @"10", @"parentID", @"false", @"homePageButtonWasSelected", @"", @"bid1_action", @"0", @"bid1_current_row", @"", @"STATUS_MESSAGE_HIDDEN", @"0", @"wbXpos", @"0", @"wbYpos", nil]];
    
    if (!params)
    {
        [self updateProgress:@"Couldn't create second parameters, please try again"];
        
        done = YES;
        
        return NO;
    }
    
    [self updateProgress:@"Checking for more shifts..."];
    
    data = [self postData:@"https://mytlc.bestbuy.com/etm/time/timesheet/etmTnsMonth.jsp" params:params];
    
    if (!data)
    {
        [self updateProgress:@"Couldn't get second schedule, please try again later"];
        
        done = YES;
        
        return NO;
    }
    
    [self updateProgress:@"Parsing second schedule"];
    
    NSMutableArray* shifts2 = [self parseSchedule:data];
    
//    if ([shifts2 count] == 0) {
//        NSLog(@"Failed");
//    }
    
    if ([shifts2 count] > 0)
    {
//        NSLog(@"No fail");
        [shifts addObjectsFromArray:shifts2];
    }
    
    if ([shifts count] > 0)
    {
        [self updateProgress:@"Adding shifts to calendar"];
        
        [self checkCalendarAccess:shifts];
    }
    else
    {
        [self updateProgress:@"No shifts to update"];
        
        done = YES;
    }
    
    [self getData:@"https://mytlc.bestbuy.com/etm/etmMenu.jsp?pageAction=logout"];
    
    return YES;
}

- (void) setMessageRead
{
    newMessageExists = NO;
}


- (void) updateProgress:(NSString*) newMessage
{
    message = newMessage;
    
    newMessageExists = YES;
}

@end
