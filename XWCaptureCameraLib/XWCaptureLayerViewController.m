//
//  XWCaptureLayerViewController.m
//  XWCaptureCamera
//
//  Created by zengchao on 15/10/27.
//  Copyright © 2015年 com.xweisoft. All rights reserved.
//

#import "XWCaptureLayerViewController.h"
#import "XWCaptureSessionManager.h"
#import "XWCaptureProgressView.h"
#import "UIImage+Capture.h"
#import "XWCameraRecordButton.h"
#import "XWCaptureViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "XWAVAssetStitcher.h"


#import "XWCaptureVideoView.h"

@interface XWCaptureViewController ()

- (void)dismiss:(id)sender;
- (void)finishPickingAssets:(id)sender;

@end

@interface XWCaptureLayerViewController()
{
    int alphaTimes;
    CGPoint currTouchPoint;
    
//    NSTimer *captureTimer;
    
    Float64 lastTime;
    Float64 currentTime;
    
    CGRect playRect;
    CGRect playRect2;
    CGRect stopRect;
    CGRect stopRect2;
}

@property (nonatomic, assign) CGRect previewRect;
@property (nonatomic, strong) XWCaptureSessionManager *captureManager;

//@property (nonatomic, strong) UIView *bottomContainerView;//除了顶部标题、拍照区域剩下的所有区域
@property (nonatomic, strong) UIView *cameraBgView;//网格、闪光灯、前后摄像头等按钮

@property (nonatomic, strong) XWCameraRecordButton *functionBtn;
@property (nonatomic, strong) UIButton *playButton;
@property (nonatomic, strong) UIButton *stopButton;

@property (nonatomic, strong) XWCaptureProgressView *progressView;

//@property (nonatomic, assign) CGFloat sumProgress;

@end

@implementation XWCaptureLayerViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        lastTime = 0;
        _maxDuration = 30;
        alphaTimes = -1;
        currTouchPoint = CGPointZero;
    }
    return self;
}

- (void)dealloc
{
//    [self.captureManager clearFiles];
    
//    [self.captureManager cancelVideoCapture];
    self.captureManager = nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //AvcaptureManager
    if (CGRectEqualToRect(_previewRect, CGRectZero)) {
        
        CGFloat width = self.view.frame.size.width;
        self.previewRect = CGRectMake(0, 0, width, width/4.0*3.0);
    }
    
    //session manager
    self.captureManager = [[XWCaptureSessionManager alloc] init];
//    [self.captureManager setCameraMode:UIImagePickerControllerCameraCaptureModeVideo];
//    [self.captureManager setCameraDevice:UIImagePickerControllerCameraDeviceRear];
//    [self.captureManager setCameraOrientation:AVCaptureVideoOrientationPortrait];
    [self.captureManager setFocusMode:AVCaptureFocusModeAutoFocus];
    
    if (self.picker.option == XWCaptureDefinition_low) {
        self.captureManager.sessionPreset = AVAssetExportPresetLowQuality;
    }
    else if (self.picker.option == XWCaptureDefinition_high) {
        self.captureManager.sessionPreset = AVAssetExportPresetHighestQuality;
    }
    else {
        self.captureManager.sessionPreset = AVAssetExportPresetMediumQuality;
    }
    
    //add watermark
    self.captureManager.watermark = self.picker.watermark;
    
    [self setupNaviItem];
    [self setupCameraBgView];
    
    GPUImageView *previewLayer = self.captureManager.previewLayer;
    previewLayer.bounds = _cameraBgView.bounds;
    previewLayer.center = CGPointMake(CGRectGetMidX(_cameraBgView.bounds), CGRectGetMidY(_cameraBgView.bounds));
    [_cameraBgView addSubview:previewLayer];
    
    //Apply animation effect to the camera's preview layer
//    CATransition *applicationLoadViewIn =[CATransition animation];
//    [applicationLoadViewIn setDuration:0.32];
//    [applicationLoadViewIn setType:kCATransitionFade];
//    [applicationLoadViewIn setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn]];
//    [previewLayer addAnimation:applicationLoadViewIn forKey:@"applicationLoadViewIn"];
//    
    [self setupProgressView];
    [self setupFunctionBtn];
    
    __weak XWCaptureLayerViewController *weakSelf = self;
    
    self.functionBtn.recordStatusOK = self.captureManager.isActive;
    self.captureManager.captureSessionOpened = ^() {
        weakSelf.functionBtn.recordStatusOK = YES;
    };
    
    self.captureManager.captureSessionClosed = ^() {
        weakSelf.functionBtn.recordStatusOK = NO;
    };
    
    self.captureManager.progressRecordingCompletion = ^(Float64 currenttime) {
        
        __strong XWCaptureLayerViewController *strongSelf = weakSelf;
        
        NSLog(@"%f",currenttime);
        
        if (strongSelf.status == XWCaptureStatus_Begin) {
            
            strongSelf->currentTime = strongSelf->lastTime+currenttime;
            
            [strongSelf.progressView setProgress:strongSelf->currentTime/strongSelf.picker.maximumCaptureDuration];
            
            if (strongSelf->currentTime >= strongSelf.picker.maximumCaptureDuration) {
                //到达最大
                strongSelf.status = XWCaptureStatus_Max;
                [strongSelf.functionBtn reset];
                return YES;
            }
        }
        
        return NO;
    };
    

}

- (void)viewWillAppear:(BOOL)animated
{
    [self.captureManager startPreview];
    
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.captureManager endVideoCapture];
    [self.captureManager stopPreview];
    
    [super viewWillDisappear:animated];
}

- (void)setupNaviItem
{
    UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    cancelButton.frame = CGRectMake(0, 0, 54, 44);
    cancelButton.tag = 100;
    cancelButton.titleLabel.font = [UIFont systemFontOfSize:18];
    [cancelButton setTitle:@"取消" forState:UIControlStateNormal];
    [cancelButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [cancelButton addTarget:self action:@selector(buttonClick:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *barItem = [[UIBarButtonItem alloc] initWithCustomView:cancelButton];
    self.navigationItem.leftBarButtonItem = barItem;
    
    UIButton *barButton = [UIButton buttonWithType:UIButtonTypeCustom];
    barButton.frame = CGRectMake(0, 0, 44, 40);
    barButton.tag = 101;
    UIImage *image = [UIImage imageFromCaptureBundle:@"camera_icon"];
    if (barButton) {
        [barButton setImage:image forState:UIControlStateNormal];
    }
    [barButton addTarget:self action:@selector(buttonClick:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *barItem2 = [[UIBarButtonItem alloc] initWithCustomView:barButton];
    self.navigationItem.rightBarButtonItem = barItem2;
}

- (void)setupFunctionBtn
{
    XWCameraRecordButton *functionBtn = [[XWCameraRecordButton alloc] initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width*0.5-60, self.previewRect.size.height+(([UIScreen mainScreen].bounds.size.height-64-self.previewRect.size.height)*0.5-60), 120, 120)];
    functionBtn.themeColor = self.picker.themeColor;
    functionBtn.tag = 200;
    [self.view addSubview:functionBtn];
    
    
    CGFloat space = (self.view.frame.size.width-120-100)/4.0;
    
    stopRect = CGRectMake(CGRectGetMaxX(functionBtn.frame)+space, self.previewRect.size.height+(([UIScreen mainScreen].bounds.size.height-64-self.previewRect.size.height)*0.5-25), 50, 50);
    
    stopRect2 = CGRectMake([UIScreen mainScreen].bounds.size.width-50, self.previewRect.size.height+(([UIScreen mainScreen].bounds.size.height-64-self.previewRect.size.height)*0.5-25), 50, 50);
    
    UIButton *stopButton = [UIButton buttonWithType:UIButtonTypeCustom];
    stopButton.frame = stopRect;
    UIImage *image2 = [UIImage imageFromCaptureBundle:@"camera_ok_btn"];
    if (image2) {
        [stopButton setBackgroundImage:image2 forState:UIControlStateNormal];
    }
    stopButton.tag = 201;
    [self.view addSubview:stopButton];
    [stopButton addTarget:self action:@selector(buttonClick:) forControlEvents:UIControlEventTouchUpInside];
    
    playRect = CGRectMake(CGRectGetMinX(functionBtn.frame)-space-50, self.previewRect.size.height+(([UIScreen mainScreen].bounds.size.height-64-self.previewRect.size.height)*0.5-25), 50, 50);
    
    playRect2 = CGRectMake(0, self.previewRect.size.height+(([UIScreen mainScreen].bounds.size.height-64-self.previewRect.size.height)*0.5-25), 50, 50);
    
    UIButton *playButton = [UIButton buttonWithType:UIButtonTypeCustom];
    playButton.frame = playRect;
    
    UIImage *image3 = [UIImage imageFromCaptureBundle:@"camera_func_btn"];
    if (image3) {
        [playButton setBackgroundImage:image3 forState:UIControlStateNormal];
    }
    playButton.tag = 202;
    [self.view addSubview:playButton];
    [playButton addTarget:self action:@selector(buttonClick:) forControlEvents:UIControlEventTouchUpInside];
    
    playButton.hidden = YES;
    stopButton.hidden = YES;
    
    self.functionBtn = functionBtn;
    self.playButton = playButton;
    self.stopButton = stopButton;
    
    __weak XWCaptureLayerViewController *weakSelf = self;
    
    functionBtn.touchDown = ^(){
        weakSelf.status = XWCaptureStatus_Begin;
    };
    
    functionBtn.touchUp = ^(){
        if (weakSelf.status == XWCaptureStatus_Max) return;
        weakSelf.status = XWCaptureStatus_Stop;
    };
}

- (void)setupCameraBgView
{
    _cameraBgView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.previewRect.size.height)];
    [self.view addSubview:self.cameraBgView];
}

- (void)setupProgressView
{
    _progressView = [[XWCaptureProgressView alloc] initWithFrame:CGRectMake(0, self.previewRect.size.height-10, self.view.frame.size.width, 30)];
    _progressView.trackColor = [UIColor grayColor];
    _progressView.progressColor = self.picker.themeColor;
    [self.view addSubview:self.progressView];
    
    __weak XWCaptureLayerViewController *weakSelf = self;
    _progressView.seekToProgress = ^(Float64 seekToProgress) {
    
        NSLog(@"seekTo--->%f",seekToProgress);
        
        __strong XWCaptureLayerViewController *strongSelf = weakSelf;
        
        if (seekToProgress >= 0.95) {
            return;
        }
    
        Float64 seekTo = seekToProgress*strongSelf.picker.maximumCaptureDuration;
        
        strongSelf->lastTime = seekTo;
        strongSelf->currentTime = seekTo;
        
        [strongSelf.captureManager seekBack:seekTo];
        
        if (seekToProgress == 0) {
            strongSelf.status = XWCaptureStatus_Unkown;
        }
        else {
            strongSelf.status = XWCaptureStatus_Stop;
        }
    };
}

- (void)buttonClick:(UIButton *)sender
{
    if (sender.tag == 100) {
        
        if (self.captureManager.allUrls.count > 0) {
            UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"放弃录制当前视频" delegate:nil cancelButtonTitle:@"取消" destructiveButtonTitle:@"放弃" otherButtonTitles:nil];
            [actionSheet showInView:self.view];
            actionSheet.delegate = self;
        }
        else {
            [self.picker dismiss:NULL];
        }
    }
    else if (sender.tag == 101) {
        //
        if (self.cameraBgView.layer.animationKeys && self.cameraBgView.layer.animationKeys.count > 0) {
            return;
        }
        
        CATransition *  tran=[CATransition animation];
        tran.removedOnCompletion = YES;
        tran.type = @"oglFlip";
        tran.duration= 0.6;
        tran.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        tran.subtype = (self.captureManager.cameraDevice==UIImagePickerControllerCameraDeviceFront)?kCATransitionFromLeft:kCATransitionFromRight;
        [self.cameraBgView.layer addAnimation:tran forKey:@"tran"];
        [self.captureManager switchCapture];
    }
    else if (sender.tag == 200) {
        
        if (self.status == XWCaptureStatus_Unkown) {
            self.status = XWCaptureStatus_Begin;
        }
    }
    else if (sender.tag == 201) {
        if (self.status == XWCaptureStatus_Max || self.status == XWCaptureStatus_Stop) {
            self.status = XWCaptureStatus_Unkown;

            NSString *outputFile = [NSString stringWithFormat:@"%@/%@.mp4",self.picker.outputFolder,[NSUUID UUID].UUIDString];
            
            if ([[NSFileManager defaultManager] fileExistsAtPath:outputFile]) {
                [[NSFileManager defaultManager] removeItemAtPath:outputFile error:nil];
            }
            
            self.navigationItem.leftBarButtonItem.enabled = NO;
            
            __weak XWCaptureLayerViewController *weakSelf = self;
            
            [self.captureManager outputVideoCapture:[NSURL fileURLWithPath:outputFile] handler:^(NSURL *path, UIImage *thumb) {
                //
                __strong XWCaptureLayerViewController *strongSelf = weakSelf;
                
                if (!strongSelf) {
                    return;
                }
                
                strongSelf->currentTime = 0;
                strongSelf->lastTime = 0;
                
                strongSelf.navigationItem.leftBarButtonItem.enabled = YES;
                
                if (strongSelf.picker.delegate && [strongSelf.picker.delegate respondsToSelector:@selector(shouldCaptureViewControllerOutputInAlbum:)]) {
                    if ([strongSelf.picker.delegate shouldCaptureViewControllerOutputInAlbum:strongSelf.picker]) {
                        //
                        ALAssetsLibrary *lib = [[ALAssetsLibrary alloc] init];
                        [lib writeVideoAtPathToSavedPhotosAlbum:path completionBlock:^(NSURL *assetURL, NSError *error) {

                        }];
                    }
                }

                if (strongSelf.picker.delegate && [strongSelf.picker.delegate respondsToSelector:@selector(captureViewControllerOutput:file:)]) {
                    [strongSelf.picker.delegate captureViewControllerOutput:strongSelf.picker file:outputFile];
                }
                
                [strongSelf.picker finishPickingAssets:nil];
            }];

        }
    }
    else if (sender.tag == 202) {
        
        if ([self.captureManager allUrls].count == 0) return;
        
        XWCaptureVideoView *videoView = [[XWCaptureVideoView alloc] initWithFrame:CGRectMake(0, 0, self.navigationController.view.frame.size.width, self.navigationController.view.frame.size.height)];
        [videoView.playUrls addObjectsFromArray:[self.captureManager allUrls]];
        videoView.coverImageView.image = [self.captureManager coverImage];
        [self.navigationController.view addSubview:videoView];
        
        [videoView showSelf];
        __weak XWCaptureLayerViewController *weakSelf = self;
        videoView.touchToClose = ^(){
            [weakSelf.captureManager startPreview];
        };
    }
}

- (void)setStatus:(XWCaptureStatus)status
{
    if (_status != status) {
        _status = status;
        
        self.functionBtn.recordStatusOK = YES;

        if (status == XWCaptureStatus_Begin) {
            
            [UIView animateWithDuration:0.4 animations:^{
                //
                self.playButton.userInteractionEnabled = NO;
                self.stopButton.userInteractionEnabled = NO;
                self.playButton.alpha = 0;
                self.stopButton.alpha = 0;
                self.playButton.frame = playRect2;
                self.stopButton.frame = stopRect2;
            } completion:^(BOOL finished) {
                //
                self.playButton.hidden = YES;
                self.stopButton.hidden = YES;
            }];
            
            if (lastTime == 0) {
                //
                
                [self.captureManager startVideoCapture];
            }
            else {
                [self.progressView insertDash:currentTime/self.picker.maximumCaptureDuration];
                
                [self.captureManager startVideoCapture];
            }
            
            self.progressView.isRecording = YES;
        }
        else if (status == XWCaptureStatus_Stop) {
            
            self.playButton.hidden = NO;
            self.stopButton.hidden = NO;
            
            [UIView animateWithDuration:0.6 animations:^{
                //
                self.playButton.userInteractionEnabled = YES;
                self.stopButton.userInteractionEnabled = YES;
                self.playButton.alpha = 1;
                self.stopButton.alpha = 1;
                self.playButton.frame = playRect;
                self.stopButton.frame = stopRect;
            }  completion:^(BOOL finished) {
                //
        
            }];
            
            self->lastTime = self->currentTime;
            
            [self.captureManager endVideoCapture];
            
            self.progressView.isRecording = NO;
        }
        else if (status == XWCaptureStatus_Max) {
            
//            [self.captureManager stopCapture];

            self.playButton.hidden = NO;
            self.stopButton.hidden = NO;
            self.functionBtn.recordStatusOK = NO;
            
            [UIView animateWithDuration:0.6 animations:^{
                //
                self.playButton.userInteractionEnabled = YES;
                self.stopButton.userInteractionEnabled = YES;
                self.playButton.alpha = 1;
                self.stopButton.alpha = 1;
                self.playButton.frame = playRect;
                self.stopButton.frame = stopRect;
            }  completion:^(BOOL finished) {
                //
        
            }];
    
            [self.captureManager endVideoCapture];
            
            self.progressView.isRecording = NO;
        }
        else if (self.status == XWCaptureStatus_Unkown) {
        
            [UIView animateWithDuration:0.4 animations:^{
                //
                self.playButton.userInteractionEnabled = NO;
                self.stopButton.userInteractionEnabled = NO;
                self.playButton.alpha = 0;
                self.stopButton.alpha = 0;
                self.playButton.frame = playRect2;
                self.stopButton.frame = stopRect2;
            } completion:^(BOOL finished) {
                //
                self.playButton.hidden = YES;
                self.stopButton.hidden = YES;
            }];
            
            self.progressView.isRecording = NO;
        }
    }
}

#pragma mark - Util
- (XWCaptureViewController *)picker
{
    return (XWCaptureViewController *)self.navigationController.parentViewController;
}


#pragma mark - ActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        [self.picker dismiss:NULL];
    }
}

@end
