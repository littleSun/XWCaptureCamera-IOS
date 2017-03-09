//
//  XWCaptureSessionManager.m
//  XWCaptureCamera
//
//  Created by zengchao on 15/10/27.
//  Copyright © 2015年 com.xweisoft. All rights reserved.
//

#import "XWCaptureSessionManager.h"
#import "UIImage+Capture.h"
#import <ImageIO/ImageIO.h>
#import "XWCaptureHelp.h"
#import "XWAVAssetStitcher.h"


#import "GPUImage.h"

static uint64_t const CaptureRequiredMinimumDiskSpaceInBytes = 49999872; // ~ 47 MB

// KVO contexts
static NSString * const CaptureSessionFocusObserverContext = @"CaptureSessionFocusObserverContext";
static NSString * const CaptureSessionStillImageIsCapturingStillImageObserverContext = @"CaptureSessionStillImageIsCapturingStillImageObserverContext";

@interface XWCaptureSessionManager()
{
    
    GPUImageVideoCamera *_videoCamera;
//    __block GPUImageOutput<GPUImageInput> *_filter;
    __block GPUImageMovieWriter *_movieWriter;
    
    NSMutableArray *_fragments;
    XWCaptureFragment *_fragment;
    
    NSURL *_outputURL;
    
    NSTimer *progressTimer;
    
    // flags
    struct {
        unsigned int recording:1;
        unsigned int isPaused:1;
        unsigned int interrupted:1;
        unsigned int compressing:1;
    } __block _flags;
}

@property (nonatomic, strong) XWAVAssetStitcher *videoStitcher;

@end

@implementation XWCaptureSessionManager

- (BOOL)isActive
{
    return ([_videoCamera.captureSession isRunning]);
}

- (BOOL)isRecording
{
    return _flags.recording;
}

#pragma mark - init

//- (BOOL)showPlatform {
//    
//    int mib[2];
//    size_t len;
//    char *machine;
//    
//    mib[0] = CTL_HW;
//    mib[1] = HW_MACHINE;
//    sysctl(mib, 2, NULL, &len, NULL, 0);
//    machine = malloc(len);
//    sysctl(mib, 2, machine, &len, NULL, 0);
//    
//    NSString *platform = [NSString stringWithCString:machine encoding:NSASCIIStringEncoding];
//    free(machine);
//    
//    if ([platform isEqualToString:@"iPhone1,1"]
//        || [platform isEqualToString:@"iPhone1,2"]
//        || [platform isEqualToString:@"iPhone2,1"]
//        || [platform isEqualToString:@"iPhone3,1"]
//        || [platform isEqualToString:@"iPhone3,2"]
//        || [platform isEqualToString:@"iPhone3,3"]
//        || [platform isEqualToString:@"iPod1,1"]
//        || [platform isEqualToString:@"iPod2,1"]
//        || [platform isEqualToString:@"iPad1,1"])
//        return NO;
//    
//    return YES;
//}

- (id)init
{
    self = [super init];
    if (self) {
        
        _frameRate = 30;
        
        _fragments = [[NSMutableArray alloc] init];
        
        
        [self _setupCamera];

    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self cancelVideoCapture];
    [self _destroyCamera];
}

#pragma mark - queue helper methods

- (void)_enqueueBlockOnMainQueue:(void (^)())block {
    dispatch_async(dispatch_get_main_queue(), ^{
        block();
    });
}

#pragma mark - camera

- (void)_setupCamera
{
    _videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionBack];
    _videoCamera.frameRate  = 30;
    
    //    videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionFront];
    //    videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset1280x720 cameraPosition:AVCaptureDevicePositionBack];
    //    videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset1920x1080 cameraPosition:AVCaptureDevicePositionBack];
    
    _videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    _videoCamera.horizontallyMirrorFrontFacingCamera = NO;
    _videoCamera.horizontallyMirrorRearFacingCamera = NO;
    
    _previewLayer = [[GPUImageView alloc] init];
    _previewLayer.fillMode = kGPUImageFillModePreserveAspectRatioAndFill;

    [_videoCamera addTarget:_previewLayer];
    
    NSDictionary *videoCompressionSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                              AVVideoCodecH264, AVVideoCodecKey,
                                              AVVideoScalingModeResizeAspectFill, AVVideoScalingModeKey,
                                              [NSNumber numberWithInteger:480], AVVideoWidthKey,
                                              [NSNumber numberWithInteger:640], AVVideoHeightKey, // square format
                                              nil];
    
    NSString *tempPath = [NSTemporaryDirectory() stringByAppendingString:@"tmp.mov"];
    _movieWriter  = [[GPUImageMovieWriter alloc] initWithMovieURL:[NSURL fileURLWithPath:tempPath] size:CGSizeMake(480, 640) fileType:AVFileTypeQuickTimeMovie outputSettings:videoCompressionSettings];
    //    _movieWriter.shouldPassthroughAudio = YES;
    _movieWriter.encodingLiveVideo = YES;
    [_videoCamera addTarget:_movieWriter];
    _videoCamera.audioEncodingTarget = _movieWriter;
    
    [_videoCamera removeTarget:_movieWriter];
    _movieWriter = nil;
    
    // add notification observers
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    
    // session notifications
//    [notificationCenter addObserver:self selector:@selector(_sessionRuntimeErrored:) name:AVCaptureSessionRuntimeErrorNotification object:_videoCamera.captureSession];
    [notificationCenter addObserver:self selector:@selector(_sessionStarted:) name:AVCaptureSessionDidStartRunningNotification object:_videoCamera.captureSession];
    [notificationCenter addObserver:self selector:@selector(_sessionStopped:) name:AVCaptureSessionDidStopRunningNotification object:_videoCamera.captureSession];
    [notificationCenter addObserver:self selector:@selector(_sessionWasInterrupted:) name:AVCaptureSessionWasInterruptedNotification object:_videoCamera.captureSession];
    [notificationCenter addObserver:self selector:@selector(_sessionInterruptionEnded:) name:AVCaptureSessionInterruptionEndedNotification object:_videoCamera.captureSession];
}

- (void)_destroyCamera
{
    [_videoCamera stopCameraCapture];
    
    if (_movieWriter) {
//        [_filter removeTarget:_movieWriter];
//        _videoCamera.audioEncodingTarget = nil;
    }
    
    [_videoCamera removeTarget:_previewLayer];
//    [_videoCamera removeTarget:_filter];
    
    // add notification observers
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    
    [notificationCenter removeObserver:self];
    
//    _filter = nil;
    _videoCamera = nil;
    _movieWriter = nil;
}

#pragma mark - AVCaptureSession

- (void)seekBack:(Float64)duration
{
    if (_fragments.count == 0) {
        return;
    }
    
    Float64 sumDuration = 0;
    
    for (XWCaptureFragment *tempFragment in _fragments.copy) {
        //...
        AVAsset *tempAsset = tempFragment.asset;
        if (tempAsset) {
            sumDuration += CMTimeGetSeconds(tempAsset.duration);
        }
        if (sumDuration > duration) {
            [_fragments removeObject:tempFragment];
        }
    }
}

- (NSArray *)allUrls
{
    NSMutableArray *urls = [NSMutableArray array];
    
    for (XWCaptureFragment *tempFragment in _fragments.copy) {
        //...
        if (tempFragment.url) {
            [urls addObject:tempFragment.url];
        }
    }
    return urls;
}

- (UIImage *)coverImage
{
    if (_fragments.count > 0) {
        XWCaptureFragment *first = _fragments[0];
        return [self movieToImage:first.asset];
    }
    return nil;
}

- (Float64)currentDuration
{
    Float64 sumDuration = 0;
    
    for (XWCaptureFragment *tempFragment in _fragments.copy) {
        AVAsset *tempAsset = tempFragment.asset;
        if (tempAsset) {
            sumDuration += CMTimeGetSeconds(tempAsset.duration);
        }
    }
    return sumDuration;
}

#pragma mark - switch

- (void)switchCapture
{
    [_videoCamera rotateCamera];
    
    _cameraDevice = [_videoCamera cameraPosition]==AVCaptureDevicePositionBack?UIImagePickerControllerCameraDeviceRear:UIImagePickerControllerCameraDeviceFront;
}

#pragma mark - preview

- (void)startPreview
{
    [_videoCamera startCameraCapture];
}

- (void)stopPreview
{
    [_videoCamera stopCameraCapture];
}

- (void)unfreezePreview
{

}

#pragma mark - photo

- (BOOL)canCapturePhoto
{
    BOOL isDiskSpaceAvailable = [XWCaptureHelp availableDiskSpaceInBytes] > CaptureRequiredMinimumDiskSpaceInBytes;
    return [self isActive] && isDiskSpaceAvailable;
}

- (UIImage *)_imageFromJPEGData:(NSData *)jpegData
{
    CGImageRef jpegCGImage = NULL;
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)jpegData);
    
    if (provider) {
        CGImageSourceRef imageSource = CGImageSourceCreateWithDataProvider(provider, NULL);
        if (imageSource) {
            if (CGImageSourceGetCount(imageSource) > 0) {
                jpegCGImage = CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);
            }
            CFRelease(imageSource);
        }
        CGDataProviderRelease(provider);
    }
    
    UIImage *image = nil;
    if (jpegCGImage) {
        image = [[UIImage alloc] initWithCGImage:jpegCGImage];
        CGImageRelease(jpegCGImage);
    }
    return image;
}

- (UIImage *)_thumbnailJPEGData:(NSData *)jpegData
{
    CGImageRef thumbnailCGImage = NULL;
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)jpegData);
    
    if (provider) {
        CGImageSourceRef imageSource = CGImageSourceCreateWithDataProvider(provider, NULL);
        if (imageSource) {
            if (CGImageSourceGetCount(imageSource) > 0) {
                NSMutableDictionary *options = [[NSMutableDictionary alloc] initWithCapacity:3];
                [options setObject:[NSNumber numberWithBool:YES] forKey:(id)kCGImageSourceCreateThumbnailFromImageAlways];
                [options setObject:[NSNumber numberWithFloat:160] forKey:(id)kCGImageSourceThumbnailMaxPixelSize];
                [options setObject:[NSNumber numberWithBool:NO] forKey:(id)kCGImageSourceCreateThumbnailWithTransform];
                thumbnailCGImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, (__bridge CFDictionaryRef)options);
            }
            CFRelease(imageSource);
        }
        CGDataProviderRelease(provider);
    }
    
    UIImage *thumbnail = nil;
    if (thumbnailCGImage) {
        thumbnail = [[UIImage alloc] initWithCGImage:thumbnailCGImage];
        CGImageRelease(thumbnailCGImage);
    }
    return thumbnail;
}

#pragma mark - video

- (BOOL)supportsVideoCapture
{
    return ([[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] count] > 0);
}

- (BOOL)canCaptureVideo
{
    BOOL isDiskSpaceAvailable = [XWCaptureHelp availableDiskSpaceInBytes] > CaptureRequiredMinimumDiskSpaceInBytes;
    return [self supportsVideoCapture] && [self isActive] && isDiskSpaceAvailable;
}

- (void)startVideoCapture
{
    NSLog(@"starting video capture");
 
    if (!_videoCamera) {
        [self _setupCamera];
    }
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];

    if (_flags.recording || _flags.isPaused)
        return;
    
    _flags.recording = YES;
    _flags.isPaused = NO;
    _flags.interrupted = NO;
    _flags.compressing = NO;
    
    _fragment = [[XWCaptureFragment alloc] init];
    
    NSDictionary *videoCompressionSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                              AVVideoCodecH264, AVVideoCodecKey,
                                              AVVideoScalingModeResizeAspectFill, AVVideoScalingModeKey,
                                              [NSNumber numberWithInteger:480], AVVideoWidthKey,
                                              [NSNumber numberWithInteger:640], AVVideoHeightKey, // square format
                                              nil];
    
    _movieWriter  = [[GPUImageMovieWriter alloc] initWithMovieURL:_fragment.url size:CGSizeMake(480, 640) fileType:AVFileTypeQuickTimeMovie outputSettings:videoCompressionSettings];
//    _movieWriter.shouldPassthroughAudio = YES;
    _movieWriter.encodingLiveVideo = YES;
    [_fragments addObject:_fragment];
    
    [_videoCamera addTarget:_movieWriter];

    _videoCamera.audioEncodingTarget = _movieWriter;
    
    [_movieWriter startRecording];

    [self setupTimer];
}

- (void)endVideoCapture
{
    NSLog(@"ending video capture");
    
    [self clearTimer];
    
    if (!_flags.recording) {
        return;
    }
    
    if (!_movieWriter) {
        
        _flags.recording = NO;
        _flags.isPaused = NO;
        _flags.interrupted = NO;
        
        NSLog(@"assetWriter unavailable to end");
        return;
    }
    
    if (_currentTime <= 0.1) {
        [self cancelVideoCapture];
        return;
    }
    
    __weak XWCaptureSessionManager *weakSelf = self;

    [_movieWriter finishRecordingWithCompletionHandler:^{
        
        __strong XWCaptureSessionManager *strongSelf = weakSelf;
        
        strongSelf->_flags.recording = NO;
        strongSelf->_flags.isPaused = NO;
        strongSelf->_flags.interrupted = NO;
        
        [strongSelf->_videoCamera removeTarget:strongSelf->_movieWriter];
        
//        strongSelf->_videoCamera.audioEncodingTarget = nil;
        strongSelf->_movieWriter = nil;
    }];

}


- (UIImage *)movieToImage:(AVAsset *)asset
{
    AVAssetImageGenerator *assetImageGenerator =[[AVAssetImageGenerator alloc] initWithAsset:asset];
    assetImageGenerator.appliesPreferredTrackTransform = YES;
    assetImageGenerator.apertureMode =AVAssetImageGeneratorApertureModeEncodedPixels;
    
    CFTimeInterval thumbnailImageTime = 1;
    NSError *thumbnailImageGenerationError = nil;
    CGImageRef thumbnailImageRef = [assetImageGenerator copyCGImageAtTime:CMTimeMake(thumbnailImageTime, 30)actualTime:NULL error:&thumbnailImageGenerationError];
    
    if(!thumbnailImageRef)
        NSLog(@"thumbnailImageGenerationError %@",thumbnailImageGenerationError);
    
    UIImage *thumbnailImage = thumbnailImageRef ? [UIImage imageWithCGImage:thumbnailImageRef] : nil;
    
    if (thumbnailImageRef) {
        CGImageRelease(thumbnailImageRef);
    }
    return thumbnailImage;
}

- (void)outputVideoCapture:(NSURL *)path handler:(void (^)(NSURL *path , UIImage *thumb))handler
{
    if (_flags.compressing)
        return;
    
    _flags.compressing = YES;
    
    __weak XWCaptureSessionManager *weakSelf = self;
    [self lowQuailtyWithInputURL:path blockHandler:^(NSURL *path_, UIImage *thumb) {
        __strong XWCaptureSessionManager *strongSelf = weakSelf;
        
        strongSelf->_flags.compressing = NO;
        
        [strongSelf->_fragments removeAllObjects];
        
        [strongSelf _enqueueBlockOnMainQueue:^{
            
            if (handler) {
                handler(path_,nil);
            }
        }];
    }];
}

- (void)lowQuailtyWithInputURL:(NSURL *)output blockHandler:(void (^)(NSURL *path, UIImage *thumb))handler {
    
    if (!output) {
        if (handler) {
            handler(nil,nil);
            return;
        }
    }
    else if (_fragments.count == 0) {
        if (handler) {
            handler(nil,nil);
            return;
        }
    }
    
    _outputURL = output;

    self.videoStitcher = [[XWAVAssetStitcher alloc] initWithOutputSize:self.previewLayer.bounds.size];
    self.videoStitcher.frameRate = self.frameRate;
    
    if (_sessionPreset) {
        self.videoStitcher.sessionPreset = _sessionPreset;
    }
    
    self.videoStitcher.watermark = self.watermark;
    
    for (XWCaptureFragment *temp in _fragments) {
        [self.videoStitcher addAsset:temp.asset withErrorHandler:^(NSError *error) {
            //
        }];
    }

    [self.videoStitcher exportTo:output withCompletionHandler:^(NSError *error) {
        //
        if (handler) {
            handler(output,nil);
        }
    }];
    
}

- (void)cancelVideoCapture
{
    [self clearTimer];
    
    _flags.recording = NO;
    _flags.isPaused = NO;
    _flags.interrupted = NO;
    
    NSLog(@"cancel video capture");
    if (_movieWriter) {
        [_movieWriter cancelRecording];
        
        [_videoCamera removeTarget:_movieWriter];
//        _videoCamera.audioEncodingTarget = nil;
        _movieWriter = nil;
    }
}

- (void)setupTimer
{
    [self clearTimer];
    
    if (!progressTimer) {
        progressTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(goTimer:) userInfo:nil repeats:YES];
    }
}

- (void)clearTimer
{
    if (progressTimer) {
        if (progressTimer.isValid) {
            [progressTimer invalidate];
        }
    }
    progressTimer = nil;
}

- (void)goTimer:(id)sender
{
    if (_flags.recording) {
        
        _currentTime = CMTimeGetSeconds(_movieWriter.duration);
        
        if (_progressRecordingCompletion) {
            _progressRecordingCompletion(_currentTime);
        }
    }
}

#pragma mark - KVO


- (void)clearFiles
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *docPath = [XWCaptureHelp cachePath];
        
        NSArray *contents = [fileManager contentsOfDirectoryAtPath:docPath error:NULL];
        NSEnumerator *e = [contents objectEnumerator];
        NSString *filename;
        while ((filename = [e nextObject])) {
            NSString *path = [docPath stringByAppendingPathComponent:filename];
            if (_outputURL && [_outputURL isEqual:[NSURL fileURLWithPath:path]]) {
                continue;
            }
            [fileManager removeItemAtPath:path error:NULL];
        }
    });
}

#pragma mark - AV NSNotifications

// capture session
- (void)_sessionRuntimeErrored:(NSNotification *)notification
{
    [self _enqueueBlockOnMainQueue:^{
//        if ([notification object] == _captureSession) {
            NSError *error = [[notification userInfo] objectForKey:AVCaptureSessionErrorKey];
            if (error) {
                NSInteger errorCode = [error code];
                switch (errorCode) {
                    case AVErrorMediaServicesWereReset:
                    {
                        NSLog(@"error media services were reset");
                        [self _destroyCamera];
                        if (!self.isActive)
                            [self startPreview];
                        break;
                    }
                    case AVErrorDeviceIsNotAvailableInBackground:
                    {
                        NSLog(@"error media services not available in background");
                        break;
                    }
                    default:
                    {
                        NSLog(@"error media services failed, error (%@)", error);
                        [self _destroyCamera];
                        if (self.isActive)
                            [self startPreview];
                        break;
                    }
                }
            }
//        }
    }];
}

- (void)_sessionStarted:(NSNotification *)notification
{
    [self _enqueueBlockOnMainQueue:^{
        if (_captureSessionOpened) {
            _captureSessionOpened();
        }
     }];
}

- (void)_sessionStopped:(NSNotification *)notification
{

    NSLog(@"session was stopped");
//    if (_flags.recording)
//        [self cancelVideoCapture];
    
    [self _enqueueBlockOnMainQueue:^{
        if (_captureSessionClosed) {
            _captureSessionClosed();
        }
    }];
}

- (void)_sessionWasInterrupted:(NSNotification *)notification
{
    [self _enqueueBlockOnMainQueue:^{
        //        if ([notification object] == _captureSession) {
        NSLog(@"session was interrupted");
        // notify stop?
        //        }
    }];
}

- (void)_sessionInterruptionEnded:(NSNotification *)notification
{
    [self _enqueueBlockOnMainQueue:^{
        //        if ([notification object] == _captureSession) {
        NSLog(@"session interruption ended");
        // notify ended?
        
        //        }
    }];
}





@end
