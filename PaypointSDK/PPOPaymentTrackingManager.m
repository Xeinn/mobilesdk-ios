//
//  PPOPaymentTrackingManager.m
//  Paypoint
//
//  Created by Robert Nash on 29/05/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "PPOPaymentTrackingManager.h"
#import "PPOPayment.h"

@interface PPOPaymentTrackingChapperone : NSObject
@property (nonatomic, strong) PPOPayment *payment;
@property (nonatomic) PAYMENT_STATE state;
-(instancetype)initWithPayment:(PPOPayment*)payment withTimeout:(NSTimeInterval)timeout;
-(void)startTimeoutTimer;
-(void)stopTimeoutTimer;
-(BOOL)hasTimedout;
@end

@interface PPOPaymentTrackingChapperone ()
@property (nonatomic) NSTimeInterval paymentTimeout;
@property (nonatomic, strong) NSTimer *timer;
@end

@implementation PPOPaymentTrackingChapperone

-(instancetype)initWithPayment:(PPOPayment *)payment withTimeout:(NSTimeInterval)timeout {
    self = [super init];
    if (self) {
        _payment = payment;
        _state = PAYMENT_STATE_NOT_STARTED;
        if (timeout < 0.0f) {
            timeout = 0;
        }
        _paymentTimeout = timeout;
    }
    return self;
}

-(BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }
    
    return [self isEqualToPaymentTrackingChapperone:object];
}

-(BOOL)isEqualToPaymentTrackingChapperone:(PPOPaymentTrackingChapperone*)chapperone {
    return (chapperone && [chapperone isKindOfClass:[PPOPaymentTrackingChapperone class]] && [self.payment isEqual:chapperone.payment]);
}

-(void)startTimeoutTimer {
    if (self.paymentTimeout >= 0) {
        self.timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(timeoutTimerFired:) userInfo:nil repeats:YES];
    }
}

-(void)stopTimeoutTimer {
    [self.timer invalidate];
    self.timer = nil;
}

-(void)timeoutTimerFired:(NSTimer*)timer {
    if (self.paymentTimeout <= 0) {
        [timer invalidate];
        timer = nil;
    } else {
        self.paymentTimeout--;
    }
}

-(BOOL)hasTimedout {
    return (self.paymentTimeout <= 0);
}

@end

@interface PPOPaymentTrackingManager ()
@property (nonatomic, strong) NSMutableSet *payments;
@end

@implementation PPOPaymentTrackingManager

//A singleton is used privately, to prevent tracking manager duplication.
+(instancetype)sharedManager {
    static id sharedManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[[self class] alloc] init];
    });
    return sharedManager;
}

-(NSMutableSet *)payments {
    if (_payments == nil) {
        _payments = [NSMutableSet new];
    }
    return _payments;
}

-(void)appendPayment:(PPOPayment*)payment withTimeout:(NSTimeInterval)timeout commenceTimeoutImmediately:(BOOL)begin {
    
    PPOPaymentTrackingManager *manager = [PPOPaymentTrackingManager sharedManager];
    
    PPOPaymentTrackingChapperone *chapperone = [[PPOPaymentTrackingChapperone alloc] initWithPayment:payment
                                                                                         withTimeout:timeout];
    
    [manager insertPaymentTrackingChapperone:chapperone];
    
    if (begin) {
        [chapperone startTimeoutTimer];
    }
    
}

-(void)removePayment:(PPOPayment*)payment {
    
    PPOPaymentTrackingManager *manager = [PPOPaymentTrackingManager sharedManager];
    
    PPOPaymentTrackingChapperone *chapperoneToDiscard = [manager chapperoneForPayment:payment];
    
    [chapperoneToDiscard stopTimeoutTimer];
    
    [manager removePaymentChapperone:chapperoneToDiscard];
    
}

-(PPOPaymentTrackingChapperone*)chapperoneForPayment:(PPOPayment*)payment {
    
    PPOPaymentTrackingManager *manager = [PPOPaymentTrackingManager sharedManager];
    
    PPOPaymentTrackingChapperone *chapperone;
    
    for (PPOPaymentTrackingChapperone *c in manager.payments) {
        
        if ([c.payment isEqual:payment]) {
            chapperone = c;
            break;
        }
        
    }
    
    return chapperone;
    
}

-(PAYMENT_STATE)stateForPayment:(PPOPayment*)payment {
    
    PPOPaymentTrackingManager *manager = [PPOPaymentTrackingManager sharedManager];
    
    PPOPaymentTrackingChapperone *chapperone = [manager chapperoneForPayment:payment];
    
    return (chapperone == nil) ? PAYMENT_STATE_NON_EXISTENT : chapperone.state;
    
}

-(void)insertPaymentTrackingChapperone:(PPOPaymentTrackingChapperone*)chapperone {
    
    PPOPaymentTrackingManager *manager = [PPOPaymentTrackingManager sharedManager];
    
    [manager.payments addObject:chapperone];
    
}

-(void)removePaymentChapperone:(PPOPaymentTrackingChapperone*)payment {
    
    PPOPaymentTrackingManager *manager = [PPOPaymentTrackingManager sharedManager];
    
    if ([manager.payments containsObject:payment]) {
        [manager.payments removeObject:payment];
    }
    
}

-(void)resumeTimeoutForPayment:(PPOPayment *)payment {
    
    PPOPaymentTrackingManager *manager = [PPOPaymentTrackingManager sharedManager];
    
    PPOPaymentTrackingChapperone *chapperone = [manager chapperoneForPayment:payment];
    
    [chapperone startTimeoutTimer];
    
}

-(void)stopTimeoutForPayment:(PPOPayment *)payment {
    
    PPOPaymentTrackingManager *manager = [PPOPaymentTrackingManager sharedManager];
    
    PPOPaymentTrackingChapperone *chapperone = [manager chapperoneForPayment:payment];
    
    [chapperone stopTimeoutTimer];
    
}

-(NSNumber*)hasPaymentSessionTimedoutForPayment:(PPOPayment *)payment {
    
    PPOPaymentTrackingManager *manager = [PPOPaymentTrackingManager sharedManager];
    
    PPOPaymentTrackingChapperone *chapperone = [manager chapperoneForPayment:payment];
    
    return (chapperone != nil) ? @([chapperone hasTimedout]) : nil;
    
}

@end