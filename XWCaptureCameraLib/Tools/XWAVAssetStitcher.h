//
//  XWAVAssetStitcher.h
//  XWCaptureCamera
//
//  Created by zengchao on 15/10/30.
//  Copyright © 2015年 com.xweisoft.*. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface XWAVAssetStitcher : NSObject
{
    __block CMTime startTime;
}
@property (nonatomic ,strong) UIImage *watermark;

@property (nonatomic, assign) int32_t frameRate;

@property (nonatomic ,copy) NSString *sessionPreset;

- (id)initWithOutputSize:(CGSize)outSize;

- (void)addAsset:(AVURLAsset *)asset withErrorHandler:(void (^)(NSError *error))errorHandler;
- (void)exportTo:(NSURL *)outputFile withCompletionHandler:(void (^)(NSError *error))completionHandler;

@end
