//
//  XWCameraRecordButton.h
//  XWCaptureCamera
//
//  Created by zengchao on 15/10/28.
//  Copyright © 2015年 com.xweisoft.*. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface XWCameraRecordButton : UIView

@property (nonatomic ,strong) UIColor *themeColor;

@property (nonatomic ,assign) BOOL recordStatusOK;

@property (nonatomic, strong) void (^touchDown)();
@property (nonatomic, strong) void (^touchUp)();

- (void)reset;

@end
