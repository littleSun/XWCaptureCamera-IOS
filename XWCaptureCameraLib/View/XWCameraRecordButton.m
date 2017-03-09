//
//  XWCameraRecordButton.m
//  XWCaptureCamera
//
//  Created by zengchao on 15/10/28.
//  Copyright © 2015年 com.xweisoft.*. All rights reserved.
//

#import "XWCameraRecordButton.h"

@interface XWCameraRecordButton()
{
    BOOL isLock;
}
@property (nonatomic ,strong) CAShapeLayer *cirleLayer;
@property (nonatomic ,strong) CATextLayer *textLayer;


@end

@implementation XWCameraRecordButton

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        
        [self drawCircle];
    }
    return self;
}

- (void)dealloc
{
    [self reset];
}

- (void)drawCircle
{
    CAShapeLayer *cirle = [CAShapeLayer layer];
    cirle.contentsScale = [UIScreen mainScreen].scale;
    CGMutablePathRef path1 = CGPathCreateMutable();
    CGPathAddEllipseInRect(path1, NULL, CGRectMake(8, 8, self.frame.size.width-16, self.frame.size.height-16));
    cirle.strokeColor = [UIColor greenColor].CGColor;
    cirle.lineWidth = 1.5;
    cirle.path = path1;
    [self.layer addSublayer:cirle];
    self.cirleLayer = cirle;
    
    CATextLayer *text = [CATextLayer layer];
    text.contentsScale = [UIScreen mainScreen].scale;
    text.string = @"按住录";
    text.fontSize = 20;
    text.foregroundColor = [UIColor greenColor].CGColor;
    text.frame = CGRectMake(10, (self.frame.size.height-30.0)*0.5, self.frame.size.width-20, 30);
    text.alignmentMode = @"center";
    [self.layer addSublayer:text];
    self.textLayer = text;
}

- (void)circleMagnify
{
    CGMutablePathRef path2 = CGPathCreateMutable();
    CGPathAddEllipseInRect(path2, NULL, CGRectMake(1, 1, self.frame.size.width-2, self.frame.size.height-2));
    
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"path"];
    animation.toValue = (__bridge id _Nullable)(path2);
    animation.duration = 0.4;
    animation.removedOnCompletion = NO;
    animation.fillMode = kCAFillModeBoth;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    
    [self.cirleLayer addAnimation:animation forKey:@"circleMagnify"];
}

- (void)circleBreathe
{
    CAKeyframeAnimation *keyframe = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
    [keyframe setValues:@[[NSNumber numberWithFloat:0.1],[NSNumber numberWithFloat:1],[NSNumber numberWithFloat:0.1]]];
    keyframe.autoreverses = YES;
    keyframe.calculationMode = kCAAnimationLinear;
    [keyframe setDuration:2.4];
    [keyframe setRepeatCount:HUGE_VALF];
    [self.cirleLayer addAnimation:keyframe forKey:@"circleBreathe"];
}

- (void)circleReset
{
    CGMutablePathRef path1 = CGPathCreateMutable();
    CGPathAddEllipseInRect(path1, NULL, CGRectMake(8, 8, self.frame.size.width-16, self.frame.size.height-16));
    
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"path"];
    animation.toValue = (__bridge id _Nullable)(path1);
    animation.duration = 0.6;
    animation.removedOnCompletion = NO;
    animation.fillMode = kCAFillModeBoth;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [self.cirleLayer addAnimation:animation forKey:@"circleMagnify2"];

    CABasicAnimation *animation2 = [CABasicAnimation animationWithKeyPath:@"opacity"];
    animation2.toValue = [NSNumber numberWithFloat:1];
    animation2.duration = 0.33;
    animation2.removedOnCompletion = YES;
    animation2.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    
    [self.cirleLayer addAnimation:animation2 forKey:@"circleBreathe"];
}

- (void)textAppear
{
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    animation.toValue = [NSNumber numberWithFloat:0];
    animation.duration = 0.4;
    animation.removedOnCompletion = NO;
    animation.fillMode = kCAFillModeBoth;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [self.textLayer addAnimation:animation forKey:@"textOpacity"];
}

- (void)textDisAppear
{
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    animation.toValue = [NSNumber numberWithFloat:1];
    animation.duration = 0.6;
    animation.removedOnCompletion = NO;
    animation.fillMode = kCAFillModeBoth;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [self.textLayer addAnimation:animation forKey:@"textOpacity2"];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
//    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    if (!self.recordStatusOK) {
        return;
    }
    
    if (isLock) {
        return;
    }
    
    isLock = YES;
    
    [self performSelector:@selector(touchesDown) withObject:nil afterDelay:0.2];
}

- (void)touchesDown
{
    isLock = NO;
    [self textAppear];
    [self circleMagnify];
    [self circleBreathe];
    
    if (_touchDown) {
        _touchDown();
    }
}

- (void)touchesUp
{
   
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    if (!isLock) {
        
        [self textDisAppear];
        [self circleReset];
        
        if (_touchUp) {
            _touchUp();
        }
    }    
    isLock = NO;
}

- (void)setThemeColor:(UIColor *)themeColor
{
    _themeColor = themeColor;
    
    if (themeColor) {
        self.cirleLayer.strokeColor = themeColor.CGColor;
        self.textLayer.foregroundColor = themeColor.CGColor;
    }
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    if (!self.recordStatusOK) {
        return;
    }
    
    [self touchesUp];
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    if (!self.recordStatusOK) {
        return;
    }
    
    [self touchesUp];
}

- (void)reset
{
    [self.cirleLayer removeAllAnimations];
    [self.textLayer removeAllAnimations];
}

@end

