//
//  PPOTimeManager.h
//  Pay360
//
//  Created by Robert Nash on 14/04/2015.
//  Copyright (c) 2016 Capita Plc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PPOTimeManager : NSObject

-(NSDate*)dateFromString:(NSString*)date;
+(BOOL)cardExpiryDateExpired:(NSString*)expiry;

@end
