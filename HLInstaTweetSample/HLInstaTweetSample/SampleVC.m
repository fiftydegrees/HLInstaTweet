//
//  SampleVC.m
//  HLInstaTweetSample
//
//  Created by Hervé Droit on 29/07/2014.
//  Copyright (c) 2014 Hervé Heurtault de Lammerville. All rights reserved.
//

#import "SampleVC.h"

#import "HLInstaTweet.h"

@interface SampleVC () <HLInstaTweetDelegate>

@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UIImageView *photoImageView;
@property (weak, nonatomic) IBOutlet UILabel *activeSessionLabel;

@end

@implementation SampleVC

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (IBAction)didTapShareStatus:(id)sender
{
    [[HLInstaTweet sharedInstaTweet] shareTextStatus:[NSString stringWithFormat:@"%@ - Rand=(%d)", _statusLabel.text, arc4random() % 100]
                                      withCompletion:^(BOOL completed) {
                                          UIAlertView *resultAV = [[UIAlertView alloc] initWithTitle:@"Result"
                                                                                             message:(completed ? @"Successfully shared" : @"An error occured")
                                                                                            delegate:nil
                                                                                   cancelButtonTitle:@"Dismiss"
                                                                                   otherButtonTitles:nil];
                                          [resultAV show];
                                          resultAV = nil;
                                      }
     andDelegate:self];
}

- (IBAction)didTapSharePhoto:(id)sender
{
    [[HLInstaTweet sharedInstaTweet] sharePhoto:_photoImageView.image
                                 withTextStatus:[NSString stringWithFormat:@"%@ - Rand=(%d)", _statusLabel.text, arc4random() % 100]
                                 withCompletion:^(BOOL completed) {
                                     UIAlertView *resultAV = [[UIAlertView alloc] initWithTitle:@"Result"
                                                                                        message:(completed ? @"Successfully shared" : @"An error occured")
                                                                                       delegate:nil
                                                                              cancelButtonTitle:@"Dismiss"
                                                                              otherButtonTitles:nil];
                                     [resultAV show];
                                     resultAV = nil;
                                 }
     andDelegate:self];
}

#pragma mark -
#pragma mark - HLInstaTweetDelegate

- (UIView *)instaTweetClientWillDisplayAccountSelectorInView:(HLInstaTweet *)twitterClient {
    return self.view;
}

- (void)instaTweetClient:(HLInstaTweet *)instaTweet switchedToAccountWithUsername:(NSString *)username {
    dispatch_async(dispatch_get_main_queue(), ^{
        _activeSessionLabel.text = [@"Now logged in as @" stringByAppendingString:username];
    });
}

@end
