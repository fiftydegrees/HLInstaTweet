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

@end

@implementation SampleVC

- (void)viewDidLoad {
    [super viewDidLoad];
    [[HLInstaTweet sharedInstaTweet] setDelegate:self];
}

- (IBAction)didTapShareStatus:(id)sender
{
    [[HLInstaTweet sharedInstaTweet] shareTextStatus:_statusLabel.text
                                      withCompletion:^(BOOL completed) {
                                          UIAlertView *resultAV = [[UIAlertView alloc] initWithTitle:@"Result"
                                                                                             message:(completed ? @"Successfully shared" : @"An error occured")
                                                                                            delegate:nil
                                                                                   cancelButtonTitle:@"Dismiss"
                                                                                   otherButtonTitles:nil];
                                          [resultAV show];
                                          resultAV = nil;
                                      }];
}

- (IBAction)didTapSharePhoto:(id)sender
{
    [[HLInstaTweet sharedInstaTweet] sharePhoto:_photoImageView.image
                                 withTextStatus:_statusLabel.text
                                 withCompletion:^(BOOL completed) {
                                     UIAlertView *resultAV = [[UIAlertView alloc] initWithTitle:@"Result"
                                                                                        message:(completed ? @"Successfully shared" : @"An error occured")
                                                                                       delegate:nil
                                                                              cancelButtonTitle:@"Dismiss"
                                                                              otherButtonTitles:nil];
                                     [resultAV show];
                                     resultAV = nil;
                                 }];
}

#pragma mark -
#pragma mark - HLInstaTweetDelegate

- (UIView *)instaTweetClientWillDisplayAccountSelectorInView:(HLInstaTweet *)twitterClient {
    return self.view;
}

@end
