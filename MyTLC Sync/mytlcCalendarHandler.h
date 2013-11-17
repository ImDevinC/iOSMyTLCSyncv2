//
//  mytlcCalendarHandler.h
//  MyTLC Sync
//
//  Created by Devin Collins on 10/25/13.
//  Copyright (c) 2013 Layer 8 Applications. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface mytlcCalendarHandler : NSObject

- (NSString*) getMessage;
- (BOOL) hasCompleted;
- (BOOL) hasNewMessage;
- (void) setMessageRead;

@end
