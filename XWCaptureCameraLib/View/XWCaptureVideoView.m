//
//  XWCaptureVideoView.m
//  XWCaptureCamera
//
//  Created by zengchao on 15/11/5.
//  Copyright © 2015年 com.xweisoft.*. All rights reserved.
//

#import "XWCaptureVideoView.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import "UIImage+Capture.h"

@implementation XWCaptureVideoView

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id) initWithFrame:(CGRect)frame
{
    if(self = [super initWithFrame:frame])
    {
        _isPlaying = NO;
        _playUrls = [[NSMutableArray alloc] init];
        
        _coverImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, (frame.size.height-frame.size.width*0.75)*0.5, frame.size.width, frame.size.width*0.75)];
        _coverImageView.clipsToBounds = YES;
        _coverImageView.contentMode = UIViewContentModeScaleAspectFill;
        [self addSubview:_coverImageView];
        
        _playerLayer = [AVPlayerLayer layer];
        _playerLayer.frame = CGRectMake(0, (frame.size.height-frame.size.width*0.75)*0.5, frame.size.width, frame.size.width*0.75);
        _playerLayer.videoGravity = @"AVLayerVideoGravityResizeAspectFill";
        _playerLayer.masksToBounds = YES;
        _playerLayer.contentsScale = [UIScreen mainScreen].scale;

        [self.layer addSublayer:_playerLayer];
        
        self.backgroundColor = [UIColor blackColor];
        
        self.playbackButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.playbackButton.frame = CGRectMake(0, (frame.size.height-frame.size.width*0.75)*0.5, frame.size.width, frame.size.width*0.75);
//        [self.playbackButton setImage:[UIImage imageNamed:@"PlayButton.png"] forState:UIControlStateNormal];
        [self.playbackButton addTarget:self action:@selector(togglePlayback:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.playbackButton];
        
        self.playbackImage = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.width*0.75)];
        self.playbackImage.contentMode = UIViewContentModeCenter;
        self.playbackImage.image = [UIImage imageFromCaptureBundle:@"capture_video_play"];
        [self.playbackButton addSubview:self.playbackImage];
        
        self.tipsLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, (frame.size.height-frame.size.width*0.75)*0.5-40, frame.size.width, 30)];
        self.tipsLabel.backgroundColor = [UIColor clearColor];
        self.tipsLabel.textColor = [UIColor colorWithWhite:1 alpha:0.8];
        self.tipsLabel.text = @"轻触退出播放";
        self.tipsLabel.textAlignment = NSTextAlignmentCenter;
        self.tipsLabel.font = [UIFont systemFontOfSize:17];
        [self addSubview:self.tipsLabel];
        
        self.alpha = 0;
    
    }
    return self;
}

- (AVPlayer*)player
{
    if (![_playerLayer player]) {
        NSMutableArray *items = [NSMutableArray array];
        for (NSURL *url in self.playUrls) {
            if ([[NSFileManager defaultManager] fileExistsAtPath:url.path]) {
                AVPlayerItem *item = [AVPlayerItem playerItemWithURL:url];
                [items addObject:item];
            }
        }
        self.player = [AVQueuePlayerPrevious queuePlayerWithItems:items];
        self.player.delegate = self;
        self.player.allowsExternalPlayback = YES;
    }
    return [_playerLayer player];
}

- (void)setPlayer:(AVPlayer*)player
{
    if (player) {
        [_playerLayer setPlayer:player];
    }
}

/* Specifies how the video is displayed within a player layer’s bounds.
 (AVLayerVideoGravityResizeAspect is default) */
- (void)setVideoFillMode:(NSString *)fillMode
{
    _playerLayer.videoGravity = fillMode;
}

- (void)togglePlayback:(id)sender
{
    if (!self.player) {
        return;
    }
    
    if(!_isPlaying)
    {
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
        UInt32 doChangeDefaultRoute = 1;
        AudioSessionSetProperty(kAudioSessionProperty_OverrideCategoryDefaultToSpeaker, sizeof(doChangeDefaultRoute), &doChangeDefaultRoute);
        
        [self play];
    }
    else
    {
        [self pause];
    }
}

- (void) play
{
    if (self.playUrls.count == 0) {
        return;
    }

    [self.player play];
    [self hideControls:YES];
    _isPlaying = YES;
}

- (void) pause
{
    [self.player pause];
    [self showControls:YES];
    _isPlaying = NO;
}

- (void)stop
{
    [self.player pause];
    _isPlaying = NO;
}


- (void)showControls:(BOOL)animated {
    NSTimeInterval duration = (animated) ? 0.2 : 0;
    
    [UIView animateWithDuration:duration animations:^() {
        _playbackImage.alpha = 1;
    }];
}

- (void)hideControls:(BOOL)animated {
    NSTimeInterval duration = (animated) ? 0.2 : 0;
    
    [UIView animateWithDuration:duration animations:^() {
        _playbackImage.alpha = 0;
    }];
}

- (void)hideSelf {
    NSTimeInterval duration = 0.5;
    
    [UIView animateWithDuration:duration animations:^{
        self.alpha = 0;
    } completion:^(BOOL finished) {
        //
        [self removeFromSuperview];
    }];
}

- (void)showSelf {
    NSTimeInterval duration = 0.5;
    
    [UIView animateWithDuration:duration animations:^{
        self.alpha = 1;
    } completion:^(BOOL finished) {
        //
        [self play];
    }];
    
//    [self showControls:NO];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    if (_playbackButton.alpha == 0) {
        return;
    }
    
    [self stop];
    
    if (_touchToClose) {
        _touchToClose();
    }
    
    [self hideSelf];
}

-(void)queuePlayerDidReceiveNotificationForSongIncrement:(AVQueuePlayerPrevious*)previousPlayer
{
    if (previousPlayer.isAtEnd) {
        [self pause];
    }
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
