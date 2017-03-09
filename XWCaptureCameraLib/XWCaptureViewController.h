//
//  XWCaptureViewController.h
//  XWCaptureCamera
//
//  Created by zengchao on 15/10/27.
//  Copyright © 2015年 com.xweisoft. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger ,XWCaptureDefinition){
    XWCaptureDefinition_low,
    XWCaptureDefinition_normal,
    XWCaptureDefinition_high
};

@class XWCaptureViewController;

@protocol XWCaptureViewControllerDelegate <NSObject>

@optional
- (BOOL)shouldCaptureViewControllerOutputInAlbum:(XWCaptureViewController *)target;


- (void)captureViewControllerOutput:(XWCaptureViewController *)target file:(NSString *)filepath;

- (void)captureViewControllerCancel:(XWCaptureViewController *)target;

@end

@interface XWCaptureViewController : UIViewController<UINavigationControllerDelegate>

@property (nonatomic ,assign) id <XWCaptureViewControllerDelegate> delegate;

@property (nonatomic ,assign) XWCaptureDefinition option;

@property (nonatomic ,strong) UIColor *themeColor;

@property (nonatomic ,strong) UIImage *watermark;

@property (nonatomic ,assign) Float64 maximumCaptureDuration;

@property (nonatomic ,copy) NSString *outputFolder;


+ (BOOL)checkStatusOk;

@end
