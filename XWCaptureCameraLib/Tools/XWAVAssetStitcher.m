//
//  XWAVAssetStitcher.m
//  XWCaptureCamera
//
//  Created by zengchao on 15/10/30.
//  Copyright © 2015年 com.xweisoft.*. All rights reserved.
//

#import "XWAVAssetStitcher.h"

@interface XWAVAssetStitcher()
{
    CGSize renderSize;
    CGSize outputSize;
    
    AVMutableComposition *composition;
    AVMutableCompositionTrack *compositionVideoTrack;
    AVMutableCompositionTrack *compositionAudioTrack;
    
    NSMutableArray *instructions;
    
    AVVideoCompositionCoreAnimationTool *avVideoCompositionCoreAnimationTool;
}
@end

@implementation XWAVAssetStitcher

- (id)initWithOutputSize:(CGSize)outSize
{
    self = [super init];
    if (self != nil)
    {
        outputSize = outSize;
        startTime = kCMTimeZero;
        _frameRate = 30;
  
        _sessionPreset = AVAssetExportPresetHighestQuality;
        
        composition = [AVMutableComposition composition];
        compositionVideoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        compositionAudioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        
        instructions = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)addAsset:(AVURLAsset *)asset withErrorHandler:(void (^)(NSError *error))errorHandler
{
    AVAssetTrack *videoTrack = nil;
    if ([asset tracksWithMediaType:AVMediaTypeVideo].count > 0)
    {
        videoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    }
    AVAssetTrack *audioTrack = nil;
    if ([asset tracksWithMediaType:AVMediaTypeAudio].count > 0)
    {
        audioTrack = [[asset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
    }
    
    AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    AVMutableVideoCompositionLayerInstruction *layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:compositionVideoTrack];
    
    CGFloat assetScaleToFitRatio = 480.0/videoTrack.naturalSize.width;
    CGAffineTransform scaleTransform = CGAffineTransformMakeScale(assetScaleToFitRatio,assetScaleToFitRatio);
//
    [layerInstruction setTransform:CGAffineTransformConcat(videoTrack.preferredTransform, scaleTransform) atTime:startTime];

    instruction.layerInstructions = @[layerInstruction];
    
    CMTime duration = asset.duration;

    instruction.timeRange = CMTimeRangeMake(startTime, duration);
    
    [instructions addObject:instruction];
    
    NSError *error = nil;
    [compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, duration) ofTrack:videoTrack atTime:startTime error:&error];
    [compositionAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, duration) ofTrack:audioTrack atTime:startTime error:&error];
    
    if (error) {
        return;
    }
    
    startTime = CMTimeRangeGetEnd(instruction.timeRange);
    
    if (_watermark) {
        
        if (avVideoCompositionCoreAnimationTool) {
            return;
        }
        
        UIImage *waterMarkImage = self.watermark;
        CALayer *waterMarkLayer = [CALayer layer];
        waterMarkLayer.contents = (id)waterMarkImage.CGImage ;
        waterMarkLayer.frame = CGRectMake(480-waterMarkImage.size.width-15.0f, 360-waterMarkImage.size.height-15.0f, waterMarkImage.size.width, waterMarkImage.size.height);
        //        waterMarkLayer.opacity = 0.6f;
        
        CALayer *parentLayer = [CALayer layer];
        CALayer *videoLayer = [CALayer layer];
        parentLayer.frame = CGRectMake(0.0f, 0.0f, 480, 360);
        videoLayer.frame = CGRectMake(0.0f, 0.0f, 480, 360);
        
        parentLayer.contentsScale = 2.0;
        waterMarkLayer.contentsScale = 2.0;
        videoLayer.contentsScale = 2.0;
        
        [parentLayer addSublayer:videoLayer];
        [parentLayer addSublayer:waterMarkLayer];
        
        avVideoCompositionCoreAnimationTool = [AVVideoCompositionCoreAnimationTool videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
    }
    else {
        avVideoCompositionCoreAnimationTool = nil;
    }
    
}


- (void)exportTo:(NSURL *)outputFile withCompletionHandler:(void (^)(NSError *error))completionHandler
{
    AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoComposition];
    
    videoComposition.instructions = instructions;
    videoComposition.renderSize = CGSizeMake(480, 360);
    videoComposition.renderScale = 1.0;
    videoComposition.animationTool = avVideoCompositionCoreAnimationTool;
    videoComposition.frameDuration = CMTimeMake(1, _frameRate);
    
    AVAssetExportSession *exporter = [AVAssetExportSession exportSessionWithAsset:composition presetName:self.sessionPreset];
    
    exporter.videoComposition = videoComposition;
    exporter.shouldOptimizeForNetworkUse = YES;
    exporter.outputFileType = AVFileTypeMPEG4;
    exporter.outputURL = outputFile;
    
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        
        switch([exporter status])
        {
            case AVAssetExportSessionStatusFailed:
            {
                completionHandler(exporter.error);
            } break;
            case AVAssetExportSessionStatusCancelled:
            case AVAssetExportSessionStatusCompleted:
            {
                //TODO:
                completionHandler(nil);
            } break;
            default:
            {
                completionHandler([NSError errorWithDomain:@"Unknown export error" code:100 userInfo:nil]);
            } break;
        }
    }];
}


@end
