//
//  XWCaptureProgressView.h
//  XWCaptureCamera
//
//  Created by zengchao on 15/10/27.
//  Copyright © 2015年 com.xweisoft.*. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface XWCaptureProgressView : UIView{
    CAShapeLayer *trackLayer;

    CAShapeLayer *progressLayer;
    
    CAShapeLayer *dashLayer;
    
    CAShapeLayer *cropLayer;
    
    UIImageView  *cropImage;
    
    NSMutableArray *dashs;
}

@property (nonatomic, strong) UIColor *trackColor;
@property (nonatomic, strong) UIColor *progressColor;
@property (nonatomic,assign) CGFloat progress;//0~1之间的数
@property (nonatomic,assign) CGFloat progressWidth;

@property (nonatomic ,assign) BOOL isRecording;

@property (nonatomic, strong) void (^seekToProgress)(Float64 progress);

- (void)setProgress:(float)progress animated:(BOOL)animated;

- (void)insertDash:(CGFloat)progressDash;

- (void)reset;

@end
