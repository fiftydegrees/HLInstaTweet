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
#define         kTwitterMaxStatusLength          140

typedef void (^TwitterClientInternalAccountCompletion)(ACAccount *account);

@interface HLInstaTweet () <UIActionSheetDelegate>

@property (nonatomic, strong) ACAccount *twitterAccount;

@property (nonatomic, strong) NSArray *accountsArray;

@property (nonatomic, strong) dispatch_semaphore_t semaphore;

@property (nonatomic, weak) id<HLInstaTweetDelegate> delegate;

@end

@implementation HLInstaTweet

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

- (NSString *)activeSessionUsername
{
    if (_twitterAccount)
        return _twitterAccount.username;
    else if ([[NSUserDefaults standardUserDefaults] objectForKey:kTwitterUserDefaultsKey])
        return [[NSUserDefaults standardUserDefaults] objectForKey:kTwitterUserDefaultsKey];
    else
        return nil;
}

- (void)switchActiveSessionAccount {
    [self authorizeAccessUsingLastUsedSession:NO];
}

#pragma mark -
#pragma mark - Sharing Management

- (void)shareTextStatus:(NSString *)status withCompletion:(HLInstaTweetPostCompletion)completion andDelegate:(id<HLInstaTweetDelegate>)delegate
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        
        if (!_twitterAccount) {
            _delegate = delegate;
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
            NSDictionary *params = @{@"status": [self formattedStatus:status enclosedWithPhoto:NO]};
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

- (void)sharePhoto:(UIImage *)photo withTextStatus:(NSString *)status withCompletion:(HLInstaTweetPostCompletion)completion andDelegate:(id<HLInstaTweetDelegate>)delegate
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        
        if (!_twitterAccount) {
            _delegate = delegate;
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
                          @"/1.1/statuses/update_with_media.json"];
            NSDictionary *params = @{@"status": [self formattedStatus:status enclosedWithPhoto:YES]};
            SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeTwitter
                                                    requestMethod:SLRequestMethodPOST
                                                              URL:url
                                                       parameters:params];
            NSData *imageData = UIImageJPEGRepresentation(photo, 1.f);
            [request addMultipartData:imageData
                             withName:@"media[]"
                                 type:@"image/jpeg"
                             filename:@"image.jpg"];
            [request setAccount:_twitterAccount];
            [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
                NSLog(@"RESP: %@", [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(urlResponse.statusCode == 200);
                });
            }];
        }
    });
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
             if ([_delegate respondsToSelector:@selector(instaTweetClientNoAccountConfigured:)])
                 [_delegate instaTweetClientNoAccountConfigured:self];
         }
         else if (accountsArray.count == 1)
         {
             _twitterAccount = accountsArray.firstObject;
             dispatch_semaphore_signal(_semaphore);
             if ([_delegate respondsToSelector:@selector(instaTweetClient:switchedToAccountWithUsername:)])
                 [_delegate instaTweetClient:self switchedToAccountWithUsername:_twitterAccount.username];
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
                             if ([_delegate respondsToSelector:@selector(instaTweetClient:switchedToAccountWithUsername:)])
                                 [_delegate instaTweetClient:self switchedToAccountWithUsername:_twitterAccount.username];
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
                     [chooseActiveAccountActionSheet showInView:[_delegate instaTweetClientWillDisplayAccountSelectorInView:self]];
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

        if ([_delegate respondsToSelector:@selector(instaTweetClient:switchedToAccountWithUsername:)])
            [_delegate instaTweetClient:self switchedToAccountWithUsername:_twitterAccount.username];
    }
}

- (void)actionSheetCancel:(UIActionSheet *)actionSheet {
    dispatch_semaphore_signal(_semaphore);
}

#pragma mark -
#pragma mark - Text formatters

- (NSString *)formattedStatus:(NSString *)status enclosedWithPhoto:(BOOL)photo
{
    NSInteger maxLength = kTwitterMaxStatusLength - (photo ? 30 : 0);
    if (status.length < maxLength)
        return status;
    else
        return [[status substringToIndex:(maxLength - 3)] stringByAppendingString:@"..."];
}

@end
