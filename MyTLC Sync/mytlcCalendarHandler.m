//
//  mytlcCalendarHandler.m
//  MyTLC Sync
//
//  Created by Devin Collins on 10/25/13.
//  Copyright (c) 2013 Layer 8 Applications. All rights reserved.
//

#import "mytlcCalendarHandler.h"
#import "mytlcShift.h"
#import <EventKit/EventKit.h>

@implementation mytlcCalendarHandler

BOOL done = NO;
EKEventStore* eventStore = nil;
NSString* message = nil;
BOOL newMessageExists = NO;

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
                    
                    if (![self deleteCalendarEntries])
                    {
                        [self updateProgress:@"Couldn't delete calendar entries, please try again"];
                        
                        done = YES;
                        
                        return;
                    }
                    
                    [self updateProgress:@"Adding shifts to calendar"];
                    
                    [self createCalendarEntries:shifts];
                }
            });
        }];
    }
}
                           
- (void) createCalendarEntries:(NSMutableArray*) shifts
{
    int count = 0;
    
    NSString* calendar_id = [self getSelectedCalendarId];
    
    int alarm_time = -1 * ([self getAlarmSettings] * 60);
    
    for (mytlcShift* shift in shifts)
    {
        EKEvent* event = [EKEvent eventWithEventStore:eventStore];
        
        event.notes = shift.department;
        
        event.title = shift.title;
        
        event.startDate = shift.startDate;
        
        event.endDate = shift.endDate;
        
        EKAlarm* alarm = [EKAlarm alarmWithRelativeOffset:alarm_time];
        
        event.alarms = [NSArray arrayWithObject:alarm];
        
        [event setCalendar:[eventStore calendarWithIdentifier:calendar_id]];
        
        NSError *err = nil;
        
        [eventStore saveEvent:event span:EKSpanThisEvent error:&err];
        
        if (!err)
        {
            count++;
        }

    }
    
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

- (BOOL) deleteCalendarEntries
{
    NSCalendar* cal = [NSCalendar currentCalendar];
    
    NSDate* date = [NSDate date];
    
    NSDateComponents* components = [cal components:(NSMonthCalendarUnit | NSYearCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit) fromDate:date];
    
    [components setHour:0];
    
    [components setMinute:0];
    
    [components setSecond:0];
    
    NSDate* startDate = [cal dateFromComponents:components];
    
    NSDate* endDate = [startDate dateByAddingTimeInterval:2592000];
    
    NSPredicate* predicate = [eventStore predicateForEventsWithStartDate:startDate endDate:endDate calendars:[NSArray arrayWithObjects:[eventStore calendarWithIdentifier:[self getSelectedCalendarId]], nil]];

    
    NSArray* events = [eventStore eventsMatchingPredicate:predicate];
    
    for (EKEvent *event in events)
    {
        if ([event.title isEqualToString:@"Work@BestBuy"])
        {
            NSError* err;
            
            if (![eventStore removeEvent:event span:EKSpanThisEvent error:&err])
            {
                if (err != nil) {
                    return NO;
                }
            }
        }
    }
    
    return YES;
}

- (int) getAlarmSettings
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];

    return [defaults integerForKey:@"alarm"];
}

- (NSString*) getData:(NSString*) url
{
    NSURL* urlRequest = [NSURL URLWithString:url];
    
    NSError* err = nil;
    
    NSString* result = [NSString stringWithContentsOfURL:urlRequest encoding:NSUTF8StringEncoding error:&err];
    
    if (!err)
    {
        return result;
    }
    
    return nil;
}

- (NSString*) getMessage
{
    return message;
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

- (NSMutableArray*) parseSchedule:(NSString*) data
{
    if ([data rangeOfString:@"calMonthTitle"].location == NSNotFound)
    {
        return nil;
    }
    
    NSRange begin = [data rangeOfString:@"calMonthTitle"];
    
    NSString* sMonth = [data substringFromIndex:begin.location + 15];
    
    NSRange end = [sMonth rangeOfString:@"</span>"];
    
    sMonth = [sMonth substringToIndex:end.location];
    
    if ([data rangeOfString:@"calYearTitle"].location == NSNotFound)
    {
        return nil;
    }
    
    begin = [data rangeOfString:@"calYearTitle"];
    
    NSString* sYear = [data substringFromIndex:begin.location + 14];
    
    end = [sYear rangeOfString:@"</span>"];
    
    sYear = [sYear substringToIndex:end.location];
    
    if ([data rangeOfString:@"calWeekDayHeader"].location == NSNotFound)
    {
        return nil;
    }
    
    data = [data substringFromIndex:[data rangeOfString:@"calWeekDayHeader"].location];
    
    if ([data rangeOfString:@"document.forms[0].NEW_MONTH_YEAR"].location == NSNotFound)
    {
        return nil;
    }
    
    data = [data substringToIndex:[data rangeOfString:@"document.forms[0].NEW_MONTH_YEAR"].location];
    
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
        if ([schedule rangeOfString:@"OFF"].location != NSNotFound)
        {
            continue;
        }
        
        if ([schedule rangeOfString:@"calendarCellRegularCurrent"].location == NSNotFound && [schedule rangeOfString:@"calendarCellRegularFuture"].location == NSNotFound)
        {
            continue;
        }
        
        NSString* date = nil;
        
        if ([schedule rangeOfString:@"calendarCellRegularCurrent"].location == NSNotFound)
        {
            begin = [schedule rangeOfString:@"calendarDateNormal"];
            
            date = [schedule substringFromIndex:begin.location + 22];
        } else {
            begin = [schedule rangeOfString:@"calendarDateCurrent"];
            
            date = [schedule substringFromIndex:begin.location + 23];
        }
        
        if (!date)
        {
            continue;
        }
        
        end = [date rangeOfString:@"</span>"];
        
        date = [date substringToIndex:end.location];
        
        NSCharacterSet* replace = [NSCharacterSet whitespaceAndNewlineCharacterSet];
        
        date = [date stringByTrimmingCharactersInSet:replace];
        
        NSArray* shifts = [schedule componentsSeparatedByString:@"<br>"];
        
        for (int i = 0; i < [shifts count]; i++)
        {
            if (([shifts[i] rangeOfString:@"AM"].location != NSNotFound && [shifts[i] rangeOfString:@"<td>"].location == NSNotFound) || ([shifts[i] rangeOfString:@"PM"].location != NSNotFound && [shifts[i] rangeOfString:@"<td>"].location == NSNotFound))
            {
                NSString* dept = @"";
                
                if (i != shifts.count - 1)
                {
                    if ([shifts[i + 1] rangeOfString:@"L-"].location != NSNotFound)
                    {
                        dept = [shifts[i + 1] stringByTrimmingCharactersInSet:replace];
                    }
                }
                
                mytlcShift* shift = [[mytlcShift alloc] init];
                
                shift.title = @"Work@BestBuy";
                
                shift.department = dept;
            
                NSRange split = [shifts[i] rangeOfString:@" - "];
                
                NSString* time = [shifts[i] substringToIndex:split.location];
                
                shift.startDate = [self parseTime:[NSString stringWithFormat:@"%@ %@, %@ %@", sMonth, date, sYear, time]];
                
                time = [shifts[i] substringFromIndex:split.location + 3];
                
                shift.endDate = [self parseTime:[NSString stringWithFormat:@"%@ %@, %@ %@", sMonth, date, sYear, time]];
                
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
    if ([data rangeOfString:@"End Hotkey for submit"].location == NSNotFound)
    {
        return nil;
    }
    
    NSRange end = [data rangeOfString:@"End Hotkey for submit"];
    
    data = [data substringFromIndex:end.location];
    
    if (([data rangeOfString:@"hidden"].location == NSNotFound) || ([data rangeOfString:@"url_login_token"].location == NSNotFound))
        {
            return nil;
        }
    
    NSRange begin = [data rangeOfString:@"hidden"];
    
    data = [data substringFromIndex:begin.location + 14];
    
    end = [data rangeOfString:@"url_login_token"];
    
    data = [data substringToIndex:end.location - 7];
    
    return data;
}

- (NSString*) parseToken2:(NSString*) data
{
    if ([data rangeOfString:@"secureToken"].location == NSNotFound)
    {
        return nil;
    }
    
    NSRange begin = [data rangeOfString:@"secureToken"];
    
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
    if ([data rangeOfString:@"wbat"].location == NSNotFound)
    {
        return nil;
    }
    
    NSRange begin = [data rangeOfString:@"wbat"];
    
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
    
    if ([data rangeOfString:@"etmMenu.jsp"].location == NSNotFound)
    {
        [self updateProgress:@"Incorrect username and password, please try again"];
        
        done = YES;
        
        return NO;
    }
    
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
    
    NSString* month = [NSString stringWithFormat:@"%D", [dateComponents month] + 1];
    
    NSString* year = [NSString stringWithFormat:@"%lD", (long) [dateComponents year]];
    
    if ([month isEqualToString:@"13"])
    {
        month = @"01";
        
        year = [NSString stringWithFormat:@"%D", [dateComponents year] + 1];
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
    
    [self updateProgress:@"Getting second months schedule"];
    
    data = [self postData:@"https://mytlc.bestbuy.com/etm/time/timesheet/etmTnsMonth.jsp" params:params];
    
    if (!data)
    {
        [self updateProgress:@"Couldn't get second schedule, please try again later"];
        
        done = YES;
        
        return NO;
    }
    
    [self updateProgress:@"Parsing second schedule"];
    
    NSMutableArray* shifts2 = [self parseSchedule:data];
    
    if ([shifts2 count] > 0)
    {
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
