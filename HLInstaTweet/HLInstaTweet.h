//
//  TwitterClient.h
//  TwitterClient
//
//  Created by Hervé HEURTAULT DE LAMMERVILLE on 26/07/14.
//  Copyright (c) 2014 Hervé HEURTAULT DE LAMMERVILLE. All rights reserved.
//

#import <Foundation/Foundation.h>

@class HLInstaTweet;

typedef void (^HLInstaTweetPostCompletion)(BOOL completed);

@protocol HLInstaTweetDelegate <NSObject>

@required

/**
 *  Triggered when several accounts are configured in the device. An actionsheet is presented in the view you return
 *
 *  @param twitterClient Claimant Twitter client
 *
 *  @return View to present account picker
 */
- (UIView *)instaTweetClientWillDisplayAccountSelectorInView:(HLInstaTweet *)twitterClient;

@optional

/**
 *  Triggered when the user switches his default account
 *
 *  @param instaTweet    Claiment HLInstaTweet instance
 *  @param username      New default account username
 */
- (void)instaTweetClient:(HLInstaTweet *)instaTweet switchedToAccountWithUsername:(NSString *)username;

/**
 *  Triggered if the user explicitly forbids access to his accounts
 *
 *  @param instaTweet Claiment HLInstaTweet instance
 */
- (void)instaTweetClientUnauthorized:(HLInstaTweet *)instaTweet;

/**
 *  Triggered if the user did not configure any Twitter account in his device
 *
 *  @param instaTweet Claiment HLInstaTweet instance
 */
- (void)instaTweetClientNoAccountConfigured:(HLInstaTweet *)instaTweet;

/**
 *  Triggered if the user cancel the presented account picker
 *
 *  @param instaTweet Claiment HLInstaTweet instance
 */
- (void)instaTweetClientDidCancelAccountPicking:(HLInstaTweet *)instaTweet;

/**
 *  Triggered if an unknown error is raised
 *
 *  @param instaTweet Claiment HLInstaTweet instance
 */
- (void)instaTweetClientUnknownError:(HLInstaTweet *)instaTweet;

@end

@interface HLInstaTweet : NSObject

/**
 *  Singleton
 *
 *  @return The shared Twitter client
 */
+ (HLInstaTweet *)sharedInstaTweet;

#pragma mark - Session

/**
 *  Should be call to get the default Twitter account username
 *
 *  @return Active session username
 */
- (NSString *)activeSessionUsername;

/**
 *  Let the user switch its default account
 */
- (void)switchActiveSessionAccount;

#pragma mark - Sharing Management

/**
 *  Share a full-text status with the default account. You must handle exceptions using delegate
 *
 *  @param status     Status to share
 *  @param completion Completion returning whether the status has been shared or not. Executed on main thread
 *  @param delegate   The delegate to use
 */
- (void)shareTextStatus:(NSString *)status
         withCompletion:(HLInstaTweetPostCompletion)completion
            andDelegate:(id<HLInstaTweetDelegate>)delegate;

/**
 *  Share a rich-media status with a status and a photo with the default account. You must handle exceptions using delegate
 *
 *  @param photo      Photo to share
 *  @param status     Status to share
 *  @param completion Completion returning whether the status bar has been shared or not. Executed on main thread
 *  @param delegate   The delegate to use
 */
- (void)sharePhoto:(UIImage *)photo
    withTextStatus:(NSString *)status
     withCompletion:(HLInstaTweetPostCompletion)completion
       andDelegate:(id<HLInstaTweetDelegate>)delegate;

@end
