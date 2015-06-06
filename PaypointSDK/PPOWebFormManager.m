//
//  PPOWebFormDelegate.m
//  Paypoint
//
//  Created by Robert Nash on 01/06/2015.
//  Copyright (c) 2015 Paypoint. All rights reserved.
//

#import "PPOWebFormManager.h"
#import "PPOWebViewController.h"
#import "PPORedirect.h"
#import "PPOPaymentTrackingManager.h"
#import "PPOPaymentEndpointManager.h"
#import "PPOCredentials.h"
#import "PPOErrorManager.h"
#import "PPOPayment.h"
#import "PPOSDKConstants.h"
#import "PPOURLRequestManager.h"

@interface PPOWebFormManager () <PPOWebViewControllerDelegate>
@property (nonatomic, copy) void(^completion)(PPOOutcome *, NSError *);
@property (nonatomic, strong) PPORedirect *redirect;
@property (nonatomic, strong) PPOWebViewController *webController;
@property (nonatomic, strong) PPOPaymentEndpointManager *endpointManager;
@property (nonatomic, strong) PPOCredentials *credentials;
@property (nonatomic, strong) NSURLSession *session;
@end

@implementation PPOWebFormManager  {
    BOOL _preventShowWebView;
    BOOL _isDismissingWebView;
}

-(instancetype)initWithRedirect:(PPORedirect *)redirect
                withCredentials:(PPOCredentials *)credentials
                    withSession:(NSURLSession *)session
            withEndpointManager:(PPOPaymentEndpointManager *)endpointManager
                 withCompletion:(void (^)(PPOOutcome *, NSError *))completion {
    
    self = [super init];
    if (self) {
        _completion = completion;
        _credentials = credentials;
        _endpointManager = endpointManager;
        _session = session;
        _redirect = redirect;
        [self loadRedirect:redirect];
    }
    return self;
}

//Loading a webpage requires a webView, but we don't want to show a webview on screen during this time.
//The webview's delegate will still fire, even if the webview is not displayed on screen.
-(void)loadRedirect:(PPORedirect*)redirect {
    if (PPO_DEBUG_MODE) {
        NSLog(@"Loading redirect web view hidden for payment with op ref: %@", redirect.payment.identifier);
    }
    self.webController = [[PPOWebViewController alloc] initWithRedirect:redirect withDelegate:self];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    CGFloat height = [UIScreen mainScreen].bounds.size.height;
    self.webController.view.frame = CGRectMake(-height, -width, width, height);
    [[[UIApplication sharedApplication] keyWindow] addSubview:self.webController.view];
}

#pragma mark - PPOWebViewController

-(void)webViewController:(PPOWebViewController *)controller completedWithPaRes:(NSString *)paRes {
    
    if (PPO_DEBUG_MODE) {
        NSLog(@"Web view concluded for payment with op ref: %@", controller.redirect.payment.identifier);
    }
    
    _preventShowWebView = YES;
    
    [PPOPaymentTrackingManager resumeTimeoutForPayment:controller.redirect.payment];
    
    if ([[UIApplication sharedApplication] keyWindow] == self.webController.view.superview) {
        if (PPO_DEBUG_MODE) NSLog(@"Removing web view for payment with op ref: %@", controller.redirect.payment.identifier);
        [self.webController.view removeFromSuperview];
    }
    
    id body;
    
    if (paRes) {
        NSDictionary *dictionary = @{@"threeDSecureResponse": @{@"pares":paRes}};
        body = [NSJSONSerialization dataWithJSONObject:dictionary options:NSJSONWritingPrettyPrinted error:nil];
    }
    
    controller.redirect.threeDSecureResumeBody = body;
    
    [self performResumeForRedirect:controller.redirect withCredentials:self.credentials];
}

-(void)performResumeForRedirect:(PPORedirect*)redirect withCredentials:(PPOCredentials*)credentials {
    
    if (PPO_DEBUG_MODE) {
        NSLog(@"Resuming payment with op ref: %@", redirect.payment.identifier);
    }
    
    NSURL *url = [self.endpointManager urlForResumePaymentWithInstallationID:credentials.installationID
                                                               transactionID:redirect.transactionID];
    
    NSURLRequest *request = [PPOURLRequestManager requestWithURL:url
                                                      withMethod:@"POST"
                                                     withTimeout:30.0f
                                                       withToken:self.credentials.token
                                                        withBody:redirect.threeDSecureResumeBody
                                                forPaymentWithID:redirect.payment.identifier];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request
                                                 completionHandler:[self resumeResponseHandlerForRedirect:redirect]];
    
    [task resume];
    
}

-(void(^)(NSData *, NSURLResponse *, NSError *))resumeResponseHandlerForRedirect:(PPORedirect*)redirect {
    
    __weak typeof(self) weakSelf = self;
    
    return ^ (NSData *data, NSURLResponse *response, NSError *networkError) {
        
        NSError *invalidJSON;
        
        id json;
        
        if (data.length > 0) {
            json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&invalidJSON];
        }
        
        PPOOutcome *outcome;
        
        if (json) {
            outcome = [[PPOOutcome alloc] initWithData:json];
        }
        
        NSError *e;
        
        if (invalidJSON) {
            
            e = [PPOErrorManager errorForCode:PPOErrorServerFailure];
            
        } else if (outcome.isSuccessful != nil && outcome.isSuccessful.boolValue == NO) {
            
            e = [PPOErrorManager errorForCode:[PPOErrorManager errorCodeForReasonCode:outcome.reasonCode.integerValue]];
            
        } else if (outcome.isSuccessful != nil && outcome.isSuccessful.boolValue == YES) {
            
            e = nil;
            
        } else if (networkError) {
            
            e = networkError;

        } else {
            
            e = [PPOErrorManager errorForCode:PPOErrorUnknown];
            
        }
        
        [weakSelf completeRedirect:redirect onMainThreadWithOutcome:outcome withError:e];
    };
}

/**
 *  The delay show mechanism is in place to prevent the web view from presenting itself, when it begins to load.
 *  Once the delay expires, the web view is shown, regardless of it's loading state.
 *  This mechanism is used to show the webview, even when a time value is not provided i.e. timeout value = 0
 *  ensuring that this method is the only method that controls web view presentation.
 */
-(void)webViewControllerDelayShowTimeoutExpired:(PPOWebViewController *)controller {
    
    if (!_preventShowWebView) {
        
        [PPOPaymentTrackingManager suspendTimeoutForPayment:controller.redirect.payment];
        
        [self.webController.view removeFromSuperview];
        
        UINavigationController *navCon = [[UINavigationController alloc] initWithRootViewController:self.webController];
        
        /*
        * Presenting controllers like this or toying with the implementing developers view heirarchy,
        * without the implementing developer's knowledge of when and how, is risky.
        * A merchant App may have an interesting animation that won't know when to 
        * terminate or change e.g. the current pulsing Paypoint logo in the demo merchant App 
        * has no indication of when to change or cancel before or after the web view is presented/dismissed.
        * May be upsetting behaviour if the implementing developer is using an interactive transitioning
        * protocol to present/dismiss the payment scene or a UIPresentationController which is managed by a 
        * transitioning context provided by the system.
        * The merchant App may have multiple child view controllers, which may work mostly independently of one another.
        * Not exposing the webview makes styling of the web view navigation bar or the presentation animation tricky
        * UIBarButtonItem text is in strings file in embedded resources bundle, for internationalisation
        * Paypoint have considered these points and are happy to release and get feedback
         */
        [[[UIApplication sharedApplication] keyWindow].rootViewController presentViewController:navCon
                                                                                       animated:YES
                                                                                     completion:nil];
    }
    
}

-(void)webViewControllerSessionTimeoutExpired:(PPOWebViewController *)webController {
    [self handleError:[PPOErrorManager errorForCode:PPOErrorThreeDSecureTimedOut] webController:webController];
}

-(void)webViewController:(PPOWebViewController *)webController failedWithError:(NSError *)error {
    [self handleError:error webController:webController];
}

-(void)webViewControllerUserCancelled:(PPOWebViewController *)webController {
    [self handleError:[PPOErrorManager errorForCode:PPOErrorUserCancelled] webController:webController];
}

-(void)handleError:(NSError *)error webController:(PPOWebViewController *)webController {
    
    _preventShowWebView = YES;
        
    [self completeRedirect:webController.redirect onMainThreadWithOutcome:nil withError:error];
    
}

-(void)completeRedirect:(PPORedirect*)redirect onMainThreadWithOutcome:(PPOOutcome*)outcome withError:(NSError*)error {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        
        //Depending on the delay show and session timeout timers, we may be currently showing the webview, or not.
        id controller = [[UIApplication sharedApplication] keyWindow].rootViewController.presentedViewController;
        
        if (controller && controller == self.webController.navigationController) {
            
            if (!_isDismissingWebView) {
                
                _isDismissingWebView = YES;
                
                [[[UIApplication sharedApplication] keyWindow].rootViewController dismissViewControllerAnimated:YES completion:^{
                    
                    _isDismissingWebView = NO;
                    
                    [PPOPaymentTrackingManager resumeTimeoutForPayment:redirect.payment];
                    
                    self.completion(outcome, error);
                    
                    _preventShowWebView = NO;
                    
                }];
                
            }
            
        } else {
            
            self.webController = nil;
            
            self.completion(outcome, error);
            
            _preventShowWebView = NO;
            
        }
        
    });
    
}

-(void)dealloc {
    [self.webController.view removeFromSuperview];
}

@end
