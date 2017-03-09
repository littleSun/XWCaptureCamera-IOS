//
//  XWCaptureSessionManager.h
//  XWCaptureCamera
//
//  Created by zengchao on 15/10/27.
//  Copyright © 2015年 com.xweisoft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "XWCaptureFragment.h"

#import "GPUImage.h"

@class XWCaptureSessionManager;

@protocol XWCaptureSessionDelegate <NSObject>
@optional

- (void)captureWillCapturePhoto:(XWCaptureSessionManager *)vision;
- (void)captureDidCapturePhoto:(XWCaptureSessionManager *)vision;
- (void)capture:(XWCaptureSessionManager *)vision capturedPhoto:(NSDictionary *)photoDict error:(NSError *)error;

- (void)capture:(XWCaptureSessionManager *)vision capturedVideo:(NSDictionary *)videoDict error:(NSError *)error;

@end

@interface XWCaptureSessionManager : NSObject
{

}

//@property (nonatomic, weak) id<PBJVisionDelegate> delegate;
@property (nonatomic, readonly, getter=isActive) BOOL active;

// setup

@property (nonatomic ,assign ,readonly) UIImagePickerControllerCameraDevice cameraDevice;
//@property (nonatomic ,assign) UIImagePickerControllerCameraCaptureMode cameraMode;
@property (nonatomic ,assign) AVCaptureFocusMode focusMode;
@property (nonatomic ,assign) AVCaptureTorchMode torchMode;

// preview

@property (nonatomic, readonly) GPUImageView *previewLayer;
//@property (nonatomic, readonly) CGRect cleanAperture;

@property (nonatomic, strong) void (^captureSessionOpened)();
@property (nonatomic, strong) void (^captureSessionClosed)();
@property (nonatomic, strong) BOOL (^progressRecordingCompletion)(Float64 duretion);

@property (nonatomic, assign, readonly) Float64 currentTime;

@property (nonatomic, strong) UIImage *watermark;

@property (nonatomic, assign) int32_t frameRate;

//输出模式
@property (nonatomic ,copy) NSString *sessionPreset;

- (void)seekBack:(Float64)duration;

- (NSArray *)allUrls;
- (UIImage *)coverImage;
- (Float64)currentDuration;

- (void)switchCapture;

- (void)startPreview;
- (void)stopPreview;

- (void)unfreezePreview; // preview is automatically timed and frozen with photo capture

// focus

//- (void)focusAtAdjustedPoint:(CGPoint)adjustedPoint;

// photo

//- (BOOL)canCapturePhoto;
//- (void)capturePhotoCompletionHandler:(void (^)(UIImage *stillImage , UIImage *thumb))handler;

// video
// use pause/resume if a session is in progress, end finalizes that recording session

@property (nonatomic, readonly, getter=isRecording) BOOL recording;

- (BOOL)supportsVideoCapture;
- (BOOL)canCaptureVideo;

- (void)startVideoCapture;
//- (void)pauseVideoCapture;
//- (void)resumeVideoCapture;
- (void)endVideoCapture;

- (void)outputVideoCapture:(NSURL *)path handler:(void (^)(NSURL *path , UIImage *thumb))handler;

- (void)cancelVideoCapture;

- (void)clearFiles;

@end
