//
//  XWCaptureLayerViewController.h
//  XWCaptureCamera
//
//  Created by zengchao on 15/10/27.
//  Copyright © 2015年 com.xweisoft. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger,XWCaptureStatus){
    XWCaptureStatus_Unkown = 0,
    XWCaptureStatus_Begin = 1,
    XWCaptureStatus_Stop = 2,
    XWCaptureStatus_Max = 3
};

@interface XWCaptureLayerViewController : UIViewController<UIActionSheetDelegate>

@property (nonatomic ,assign) CGFloat maxDuration;

@property (nonatomic ,assign) XWCaptureStatus status;

@end
