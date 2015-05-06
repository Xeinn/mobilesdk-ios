//
//  PPOPaymentBaseURLManager.m
//  Paypoint
//
//  Created by Robert Nash on 17/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "PPOPaymentBaseURLManager.h"

@implementation PPOPaymentBaseURLManager

+(NSURL*)baseURLForEnvironment:(PPOEnvironment)environment {
    
    //api.mite.paypoint.net:2443

    switch (environment) {
        case PPOEnvironmentMerchantIntegrationTestingEnvironment:
            return [NSURL URLWithString:@"http://localhost:5000"];
            break;
            
        default:
            return nil;
            break;
    }
    
}

@end
