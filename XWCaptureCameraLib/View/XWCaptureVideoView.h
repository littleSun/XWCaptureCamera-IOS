//
//  XWCaptureVideoView.h
//  XWCaptureCamera
//
//  Created by zengchao on 15/11/5.
//  Copyright © 2015年 com.xweisoft.*. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AVQueuePlayerPrevious.h"
#import "AVFoundation/AVPlayerLayer.h"

@interface XWCaptureVideoView : UIView<AVQueuePlayerPreviousDelegate>
{
    BOOL _isPlaying;
}

@property (nonatomic, strong) UILabel *tipsLabel;
@property (nonatomic, strong) UIImageView *playbackImage;
@property (nonatomic, strong) UIButton * playbackButton;
@property (nonatomic, strong) AVQueuePlayerPrevious * player;
@property (nonatomic, strong) AVPlayerLayer * playerLayer;

@property (nonatomic, strong) UIImageView *coverImageView;
@property (nonatomic, strong) NSMutableArray * playUrls;


@property (nonatomic, strong) void (^touchToClose)();

- (void)setVideoFillMode:(NSString *)fillMode;

//- (void)insertPackingBox:(NSURL *)url;

- (void)togglePlayback:(id)sender;
- (void)play;
- (void)pause;

//- (void)toggleControls;
- (void)showControls:(BOOL)animated;
- (void)hideControls:(BOOL)animated;
- (void)hideSelf;
- (void)showSelf;

@end
