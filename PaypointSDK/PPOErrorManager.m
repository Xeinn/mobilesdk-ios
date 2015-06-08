//
//  PPOErrorManager.m
//  Paypoint
//
//  Created by Robert Nash on 09/04/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "PPOErrorManager.h"

@implementation PPOErrorManager

+(NSString*)errorDomainForReasonCode:(NSInteger)reasonCode {
    
    NSString *domain;
    
    switch (reasonCode) { //A reason code is a Paypoint reason code.
            
        case 0: //Success, so should not be considered as needing an 'error domain' at all
            break;
            
        default:
            domain = PPOPaypointSDKErrorDomain; // Use this domain for everything. Even if reason code is unknown.
            break;
    }
    
    return domain;
}

+(PPOErrorCode)errorCodeForReasonCode:(NSInteger)reasonCode {
    
    PPOErrorCode code = PPOErrorUnknown;
    
    /*
     * Reason codes 7 and 8 are related to three d secure suspended state.
     * This conversion table returns processing failed, because we do not want to 
     * recover a failed payment if it is in this state. Nor do we want to let the 
     * implementing developer know about this state.
     */
    switch (reasonCode) {
        case 1: code = PPOErrorBadRequest; break;
        case 2: code = PPOErrorAuthenticationFailed; break;
        case 3: code = PPOErrorClientTokenExpired; break;
        case 4: code = PPOErrorUnauthorisedRequest; break;
        case 5: code = PPOErrorTransactionDeclined; break;
        case 6: code = PPOErrorServerFailure; break;
        case 7: code = PPOErrorTransactionProcessingFailed; break;
        case 8: code = PPOErrorTransactionProcessingFailed; break;
        case 9: code = PPOErrorPaymentProcessing; break;
        case 10: code = PPOErrorPaymentNotFound; break;
        default:
            break;
    }
        
    return code;
    
}

+(BOOL)safeToRetryPaymentWithoutRiskOfDuplication:(NSError *)error {
    
    //NetworkErrorDuring
    //TransactionTimeout
    //ServerError
    
    NSArray *acceptable = @[@(PPOErrorBadRequest), @(0)];
    
}

+(NSError*)errorForCode:(PPOErrorCode)code {
    
    switch (code) {
        case PPOErrorBadRequest: {
            return [NSError errorWithDomain:PPOPaypointSDKErrorDomain
                                       code:PPOErrorBadRequest
                                   userInfo:@{
                                              NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"The request was not well formed", @"Networking error")
                                              }
                    ];
        }
            break;
            
        case PPOErrorCardExpiryDateExpired:
            return [NSError errorWithDomain:PPOPaypointSDKErrorDomain
                                       code:PPOErrorCardExpiryDateExpired
                                   userInfo:@{
                                              NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Expiry date is in the past", @"Failure message for card validation")
                                              }
                    ];
            break;
            
        case PPOErrorMasterSessionTimedOut: {
            return [NSError errorWithDomain:PPOPaypointSDKErrorDomain
                                       code:PPOErrorMasterSessionTimedOut
                                   userInfo:@{
                                              NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Payment session timedout", @"Failure message for card validation")
                                              }
                    ];
        }
            break;
            
        case PPOErrorPaymentSuspendedForThreeDSecure: {
            return [NSError errorWithDomain:PPOPaypointSDKErrorDomain
                                       code:PPOErrorPaymentSuspendedForThreeDSecure
                                   userInfo:@{
                                              NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Payment currently suspended awaiting 3D Secure processing.", @"Feedback message for payment status")
                                              }
                    ];
        }
            break;
            
        case PPOErrorTransactionDeclined: {
            return [NSError errorWithDomain:PPOPaypointSDKErrorDomain
                                       code:PPOErrorTransactionDeclined
                                   userInfo:@{
                                              NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Transaction declined.", @"Feedback message for payment status")
                                              }
                    ];
        }
            break;
            
        case PPOErrorAuthenticationFailed: {
            return [NSError errorWithDomain:PPOPaypointSDKErrorDomain
                                       code:PPOErrorAuthenticationFailed
                                   userInfo:@{
                                              NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Authentication failed", @"Failure message for authentication")
                                              }
                    ];
        }
            break;
            
        case PPOErrorPaymentProcessing:
            return [NSError errorWithDomain:PPOPaypointSDKErrorDomain
                                       code:PPOErrorPaymentProcessing
                                   userInfo:@{
                                              NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Transaction in progress", @"Status message for payment status check")
                                              }
                    ];
            break;
            
        case PPOErrorSuppliedBaseURLInvalid: {
            return [NSError errorWithDomain:PPOPaypointSDKErrorDomain
                                       code:PPOErrorSuppliedBaseURLInvalid
                                   userInfo:@{
                                              NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"PPOPaymentManager is missing a base URL", @"Failure message for BaseURL check")
                                              }
                    ];
        } break;
        case PPOErrorInstallationIDInvalid: {
            return [NSError errorWithDomain:PPOPaypointSDKErrorDomain
                                       code:PPOErrorInstallationIDInvalid
                                   userInfo:@{
                                              NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"The installation ID is missing", @"Failure message for credentials check")
                                              }
                    ];
        } break;
        case PPOErrorCardPanInvalid: {
            return [NSError errorWithDomain:PPOPaypointSDKErrorDomain
                                       code:PPOErrorCardPanInvalid
                                   userInfo:@{ //Description as per BLU-15022
                                              NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Invalid card number. Must be numbers only.", @"Failure message for a card validation check")
                                              }
                    ];
        } break;
        case PPOErrorLuhnCheckFailed: {
            return [NSError errorWithDomain:PPOPaypointSDKErrorDomain
                                       code:PPOErrorLuhnCheckFailed
                                   userInfo:@{
                                              NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Invalid card number.", @"Failure message for a card validation check")
                                              }
                    ];
        } break;
        case PPOErrorCVVInvalid: {
            return [NSError errorWithDomain:PPOPaypointSDKErrorDomain
                                       code:PPOErrorCVVInvalid
                                   userInfo:@{
                                              NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Invalid CVV.", @"Failure message for a card validation check")
                                              }
                    ];
        } break;
            
        case PPOErrorCardExpiryDateInvalid: {
            return [NSError errorWithDomain:PPOPaypointSDKErrorDomain
                                       code:PPOErrorCardExpiryDateInvalid
                                   userInfo:@{
                                              NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Invalid expiry date. Must be YY MM.", @"Failure message for a card validation check")
                                              }
                    ];
        } break;
        case PPOErrorCurrencyInvalid: {
            return [NSError errorWithDomain:PPOPaypointSDKErrorDomain
                                       code:PPOErrorCurrencyInvalid
                                   userInfo:@{
                                              NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"The specified currency is invalid", @"Failure message for a transaction validation check")
                                              }
                    ];
        } break;
        case PPOErrorPaymentAmountInvalid: {
            return [NSError errorWithDomain:PPOPaypointSDKErrorDomain
                                       code:PPOErrorPaymentAmountInvalid
                                   userInfo:@{
                                              NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Payment amount is invalid", @"Failure message for a transaction validation check")
                                              }
                    ];
        } break;
        case PPOErrorCredentialsNotFound: {
            return [NSError errorWithDomain:PPOPaypointSDKErrorDomain
                                       code:PPOErrorCredentialsNotFound
                                   userInfo:@{
                                              NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Credentials not supplied", @"Failure message for payment parameters integrity check")
                                              }
                    ];
        } break;
        case PPOErrorServerFailure: {
            return [NSError errorWithDomain:PPOPaypointSDKErrorDomain
                                       code:PPOErrorServerFailure
                                   userInfo:@{
                                              NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"There was an error from the server at Paypoint", @"Generic paypoint server error failure message")
                                              }
                    ];
        } break;
        case PPOErrorClientTokenExpired: {
            return [NSError errorWithDomain:PPOPaypointSDKErrorDomain
                                       code:PPOErrorClientTokenExpired
                                   userInfo:@{
                                              NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"The supplied bearer token has expired", @"Failure message for payment error")
                                              }
                    ];
        } break;
        case PPOErrorClientTokenInvalid: {
            return [NSError errorWithDomain:PPOPaypointSDKErrorDomain
                                       code:PPOErrorClientTokenInvalid
                                   userInfo:@{
                                              NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"The supplied token is invalid", @"Failure message for a transaction validation check")
                                              }
                    ];
        } break;
        case PPOErrorUnauthorisedRequest: {
            return [NSError errorWithDomain:PPOPaypointSDKErrorDomain
                                       code:PPOErrorUnauthorisedRequest
                                   userInfo:@{
                                              NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"The supplied token does not have sufficient permissions", @"Failure message for account restriction")
                                              }
                    ];
        } break;
        case PPOErrorTransactionProcessingFailed: {
            return [NSError errorWithDomain:PPOPaypointSDKErrorDomain
                                       code:PPOErrorTransactionProcessingFailed
                                   userInfo:@{
                                              NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"The transaction failed to process correctly", @"Failure message for payment failure")
                                              }
                    ];
        } break;
        case PPOErrorUnknown: {
            return [NSError errorWithDomain:PPOPaypointSDKErrorDomain
                                       code:PPOErrorUnknown
                                   userInfo:@{
                                              NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"There has been an unknown error.", @"Failure message for payment failure")
                                              }
                    ];
        } break;
        case PPOErrorProcessingThreeDSecure: {
            return [NSError errorWithDomain:PPOPaypointSDKErrorDomain
                                       code:PPOErrorProcessingThreeDSecure
                                   userInfo:@{
                                              NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"There has been an error processing your payment via 3D secure.", @"Failure message for 3D secure payment failure")
                                              }
                    ];
        } break;
        case PPOErrorThreeDSecureTimedOut: {
            return [NSError errorWithDomain:PPOPaypointSDKErrorDomain
                                       code:PPOErrorThreeDSecureTimedOut
                                   userInfo:@{
                                              NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"3D secure timed out.", @"Failure message for 3D secure payment failure")
                                              }
                    ];
        } break;
        case PPOErrorPaymentNotFound: {
            return [NSError errorWithDomain:PPOPaypointSDKErrorDomain
                                       code:PPOErrorPaymentNotFound
                                   userInfo:@{
                                              NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"This payment did not complete or is not known.", @"Failure message for payment status")
                                              }
                    ];
        }
            break;
        case PPOErrorUserCancelled: {
            return [NSError errorWithDomain:PPOPaypointSDKErrorDomain
                                       code:PPOErrorUserCancelled
                                   userInfo:@{
                                              NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"User cancelled 3D secure.", @"Failure message for 3D secure payment failure")
                                              }
                    ];
        } break;
        case PPOErrorPaymentManagerOccupied: {
            return [NSError errorWithDomain:PPOPaypointSDKErrorDomain
                                       code:PPOErrorPaymentManagerOccupied
                                   userInfo:@{
                                              NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Payment manager occupied. Please wait until current payment finishes.", @"Failure message for 3D secure payment failure")
                                              }
                    ];
        }
            break;
            
        default: return nil; break;
    }
    
}

@end
