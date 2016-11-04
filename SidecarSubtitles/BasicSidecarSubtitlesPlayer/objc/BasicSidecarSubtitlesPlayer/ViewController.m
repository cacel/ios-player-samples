//
//  ViewController.m
//  BasicSidecarSubtitlesPlayer
//
//  Copyright (c) 2015 Brightcove, Inc. All rights reserved.
//  License: https://accounts.brightcove.com/en/terms-and-conditions
//

#import "ViewController.h"

@import BrightcovePlayerSDK;
@import BrightcoveSidecarSubtitles;

@import MediaPlayer;
@import AVFoundation;
@import AVKit;

// ** Customize these values with your own account information **
static NSString * const kViewControllerPlaybackServicePolicyKey = @"BCpkADawqM1Sh_RsWQTEtCCpMbpKrbKQN_lhGY3fSZE-Cbp67h2aDRTDuifFXnT3yEYrxPNy640VTr224uWjtky-6YDzzqIDRyjqZq_wXu4Py0MSUMdf2rPmS102D6QGi8bIEQEXutS-eeVp";
static NSString * const kViewControllerAccountID = @"3636334180001";
static NSString * const kViewControllerVideoID = @"3987127390001";

@interface ViewController () <BCOVPlaybackControllerDelegate, BCOVPUIPlayerViewDelegate>

@property (nonatomic, strong) BCOVPlaybackService *service;
@property (nonatomic, strong) id<BCOVPlaybackController> playbackController;
@property (nonatomic) BCOVPUIPlayerView *playerView;

@property (nonatomic, weak) IBOutlet UIView *videoContainer;
@property (nonatomic, strong) AVPlayerViewController *playerViewController;

@end

@implementation ViewController

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self)
    {
        [self setup];
    }
    return self;
}

- (void)setup
{
    BCOVPlayerSDKManager *manager = [BCOVPlayerSDKManager sharedManager];

    _playbackController = [manager createSidecarSubtitlesPlaybackControllerWithViewStrategy:nil];
    _playbackController.delegate = self;
    _playbackController.autoAdvance = YES;
    _playbackController.autoPlay = YES;

    _service = [[BCOVPlaybackService alloc] initWithAccountId:kViewControllerAccountID policyKey:kViewControllerPlaybackServicePolicyKey];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    BCOVPUIPlayerViewOptions *options = [[BCOVPUIPlayerViewOptions alloc] init];
    options.presentingViewController = self;

    BCOVPUIBasicControlView *controlView = [BCOVPUIBasicControlView basicControlViewWithVODLayout];
    _playerView = [[BCOVPUIPlayerView alloc] initWithPlaybackController:nil options:nil controlsView:controlView];
    _playerView.frame = _videoContainer.bounds;
    _playerView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [_videoContainer addSubview:_playerView];

    _playerView.playbackController = _playbackController;

    [self requestContentFromPlaybackService];
}

- (void)requestContentFromPlaybackService
{
    [self.service findVideoWithVideoID:kViewControllerVideoID parameters:nil completion:^(BCOVVideo *video, NSDictionary *jsonResponse, NSError *error) {
        
        if (video)
        {
            BCOVVideo *updatedVideo = [video update:^(id<BCOVMutableVideo> mutableVideo) {
                NSArray *textTracks = @[];
                textTracks = [self setupSubtitles];
                NSMutableDictionary *updatedDictionary = [mutableVideo.properties mutableCopy];
                updatedDictionary[kBCOVSSVideoPropertiesKeyTextTracks] = textTracks;
                mutableVideo.properties = updatedDictionary;
            }];
            [self.playbackController setVideos:@[updatedVideo]];
        }
        else
        {
            NSLog(@"ViewController Debug - Error retrieving video: `%@`", error);
        }
        
    }];
}

- (NSArray *)setupSubtitles
{
    NSArray *textTracks = @[@{ kBCOVSSTextTracksKeyKind: kBCOVSSTextTracksKindSubtitles,
                               kBCOVSSTextTracksKeyLabel: @"English",
                               kBCOVSSTextTracksKeyDefault: @YES,
                               kBCOVSSTextTracksKeySourceLanguage: @"en",
                               kBCOVSSTextTracksKeySource: @"Add your VTT caption file URL here",
                               kBCOVSSTextTracksKeyMIMEType: @"text/vtt"
                               }
                            ];
    return textTracks;
}

#pragma mark BCOVPlaybackControllerDelegate Methods

- (void)playbackController:(id<BCOVPlaybackController>)controller playbackSession:(id<BCOVPlaybackSession>)session didReceiveLifecycleEvent:(BCOVPlaybackSessionLifecycleEvent *)lifecycleEvent
{
    NSLog(@"ViewController Debug - Received lifecycle event.");
}


#pragma mark UI Styling

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

@end
