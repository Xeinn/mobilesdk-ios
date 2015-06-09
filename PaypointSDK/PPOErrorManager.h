//
//  PPOErrorManager.h
//  Paypoint
//
//  Created by Robert Nash on 09/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "PPOError.h"
#import "PPOPrivateError.h"
#import "PPOOutcome.h"

@interface PPOErrorManager : NSObject

+(NSError *)parsePaypointReasonCode:(NSInteger)code;

+(NSError*)buildErrorForPrivateErrorCode:(PPOPrivateError)code;

+(NSError*)buildErrorForPaymentErrorCode:(PPOPaymentError)code;

+(NSError*)buildErrorForValidationErrorCode:(PPOLocalValidationError)code;

+(NSError*)buildCustomerFacingErrorFromError:(NSError*)error;

@end
