//
//  TwitterClient.m
//  TwitterClient
//
//  Created by Hervé HEURTAULT DE LAMMERVILLE on 26/07/14.
//  Copyright (c) 2014 Hervé HEURTAULT DE LAMMERVILLE. All rights reserved.
//

#import "HLInstaTweet.h"

#import <Accounts/Accounts.h>
#import <Social/Social.h>
#import <Twitter/Twitter.h>

#define         kTwitterUserDefaultsKey          @"default_twitter_account"

typedef void (^TwitterClientInternalAccountCompletion)(ACAccount *account);

@interface HLInstaTweet () <UIActionSheetDelegate>

@property (nonatomic, strong) ACAccount *twitterAccount;

@property (nonatomic, strong) NSArray *accountsArray;

@property (nonatomic, strong) dispatch_semaphore_t semaphore;

@end

@implementation HLInstaTweet

@synthesize delegate;

+ (HLInstaTweet *)sharedInstaTweet
{
    static HLInstaTweet *_sharedInstaTweet;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstaTweet = [[self alloc] init];
        _sharedInstaTweet.semaphore = dispatch_semaphore_create(0);
    });
    return _sharedInstaTweet;
}

#pragma mark -
#pragma mark - Session

- (void)activeSession {
    [self authorizeAccessUsingLastUsedSession:YES];
}

- (NSString *)activeSessionUsername {
    return _twitterAccount ? _twitterAccount.username : nil;
}

- (void)switchActiveSessionAccount {
    [self authorizeAccessUsingLastUsedSession:NO];
}

#pragma mark -
#pragma mark - Sharing Management

- (void)shareTextStatus:(NSString *)status withCompletion:(HLInstaTweetPostCompletion)completion
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        
        if (!_twitterAccount) {
            [self activeSession];
            dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
        }
        
        if (!_twitterAccount) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO);
            });
        }
        else
        {
            NSURL *url = [NSURL URLWithString:@"https://api.twitter.com"
                          @"/1.1/statuses/update.json"];
            NSDictionary *params = @{@"status": status};
            SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeTwitter
                                                    requestMethod:SLRequestMethodPOST
                                                              URL:url
                                                       parameters:params];
            [request setAccount:_twitterAccount];
            [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(urlResponse.statusCode == 200);
                });
            }];
        }
    });
}

- (void)sharePhoto:(UIImage *)photo withTextStatus:(NSString *)status withCompletion:(HLInstaTweetPostCompletion)completion
{
    
}

#pragma mark - Internal Helper

- (void)authorizeAccessUsingLastUsedSession:(BOOL)cached
{
    ACAccountStore *accountStore = [[ACAccountStore alloc] init];
    ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    
    [accountStore requestAccessToAccountsWithType:accountType
                                          options:nil
                                       completion:^(BOOL granted, NSError *error)
     {
         NSArray *accountsArray = [accountStore accountsWithAccountType:accountType];
         
         if (accountsArray.count == 0) {
             dispatch_semaphore_signal(_semaphore);
             if ([delegate respondsToSelector:@selector(instaTweetClientNoAccountConfigured:)])
                 [delegate instaTweetClientNoAccountConfigured:self];
         }
         else if (accountsArray.count == 1)
         {
             _twitterAccount = accountsArray.firstObject;
             dispatch_semaphore_signal(_semaphore);
             if ([delegate respondsToSelector:@selector(instaTweetClient:switchedToAccountWithUsername:)])
                 [delegate instaTweetClient:self switchedToAccountWithUsername:_twitterAccount.username];
         }
         else if (accountsArray.count > 1)
         {
             if (cached)
             {
                 NSString *cachedAccount = [[NSUserDefaults standardUserDefaults] objectForKey:kTwitterUserDefaultsKey];
                 if (cachedAccount)
                 {
                     for (ACAccount *account in accountsArray)
                         if ([account.identifier isEqualToString:cachedAccount]) {
                             _twitterAccount = account;
                             dispatch_semaphore_signal(_semaphore);
                             break;
                         }
                 }
             }
             
             if (!cached ||
                 !_twitterAccount)
             {
                 UIActionSheet *chooseActiveAccountActionSheet = [[UIActionSheet alloc] initWithTitle:@"Choose an account"
                                                                                             delegate:self
                                                                                    cancelButtonTitle:nil
                                                                               destructiveButtonTitle:nil
                                                                                    otherButtonTitles:nil];
                 for (ACAccount *account in accountsArray) {
                     [chooseActiveAccountActionSheet addButtonWithTitle:[@"@" stringByAppendingString:account.username]];
                 }
                 
                 [chooseActiveAccountActionSheet addButtonWithTitle:@"Cancel"];
                 chooseActiveAccountActionSheet.cancelButtonIndex = accountsArray.count;
                 chooseActiveAccountActionSheet.tag = 1;
                 
                 _accountsArray = accountsArray;
                 dispatch_async(dispatch_get_main_queue(), ^{
                     [chooseActiveAccountActionSheet showInView:[delegate instaTweetClientWillDisplayAccountSelectorInView:self]];
                 });
             }
         }
     }];
}

#pragma mark -
#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (actionSheet.tag == 1 &&
        buttonIndex < _accountsArray.count)
    {
        _twitterAccount = _accountsArray[buttonIndex];
        dispatch_semaphore_signal(_semaphore);
        
        [[NSUserDefaults standardUserDefaults] setObject:_twitterAccount.identifier forKey:kTwitterUserDefaultsKey];
        [[NSUserDefaults standardUserDefaults] synchronize];

        if ([delegate respondsToSelector:@selector(instaTweetClient:switchedToAccountWithUsername:)])
            [delegate instaTweetClient:self switchedToAccountWithUsername:_twitterAccount.username];
    }
}

- (void)actionSheetCancel:(UIActionSheet *)actionSheet {
    dispatch_semaphore_signal(_semaphore);
}

@end
