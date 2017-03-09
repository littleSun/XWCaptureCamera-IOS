//
//  XWCaptureProgressView.m
//  XWCaptureCamera
//
//  Created by zengchao on 15/10/27.
//  Copyright © 2015年 com.xweisoft.*. All rights reserved.
//

#import "XWCaptureProgressView.h"
#import "UIImage+Capture.h"

@interface XWCaptureProgressView()
{
    CGPoint touchedPoint;
}
@property (nonatomic,assign) CGFloat touchProgress;

@end

@implementation XWCaptureProgressView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        touchedPoint = CGPointZero;
        dashs = [NSMutableArray array];
        
        trackLayer = [CAShapeLayer layer];
        trackLayer.contentsScale = [UIScreen mainScreen].scale;
        [self.layer addSublayer:trackLayer];
        
        progressLayer = [CAShapeLayer layer];
        progressLayer.contentsScale = [UIScreen mainScreen].scale;
        [self.layer addSublayer:progressLayer];
        [progressLayer setLineJoin:kCALineJoinBevel];

        cropLayer = [CAShapeLayer layer];
        cropLayer.contentsScale = [UIScreen mainScreen].scale;
        [self.layer addSublayer:cropLayer];
        cropLayer.strokeColor = [UIColor orangeColor].CGColor;
        [cropLayer setLineJoin:kCALineJoinBevel];
        
        dashLayer = [CAShapeLayer layer];
        dashLayer.strokeColor = [UIColor grayColor].CGColor;
        dashLayer.contentsScale = [UIScreen mainScreen].scale;
        [self.layer addSublayer:dashLayer];
        [dashLayer setLineJoin:kCALineJoinBevel];
        
        cropImage = [[UIImageView alloc] init];
        UIImage *image = [UIImage imageFromCaptureBundle:@"camera_crop_btn"];
        cropImage.image = image;
        [self addSubview:cropImage];
        cropImage.hidden = YES;
        cropImage.userInteractionEnabled = YES;
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(cropPan:)];
        [cropImage addGestureRecognizer:pan];
        
        //默认5
        self.progressWidth = 5;
    }
    return self;
}

- (void)setTrack
{
    UIBezierPath *path = [[UIBezierPath alloc] init];
    [path moveToPoint:CGPointMake(0, 0)];
    [path addLineToPoint:CGPointMake(self.frame.size.width, 0)];
    [path closePath];
    
//    trackPath = path;
    trackLayer.path = path.CGPath;
}

- (void)setProgress
{
    CGFloat x = 0;
    
    UIBezierPath *path = [[UIBezierPath alloc] init];
    [path moveToPoint:CGPointMake(x, 0)];
    
//    for (NSInteger i = 0; i < dashs.count; i++) {
//        
//        CGFloat line = self.frame.size.width*[dashs[i] floatValue];
//        
//        if (i==0) {
//            x = line;
//            [path addLineToPoint:CGPointMake(x, 0)];
//        }
//        else {
//            [path moveToPoint:CGPointMake(x+3, 0)];
//            x = line;
//            [path addLineToPoint:CGPointMake(x, 0)];
//        }
//    }
//
//    if (x!=0) {
//        x += 3;
//        [path moveToPoint:CGPointMake(x, 0)];
//    }
//
//    if (self.frame.size.width*self.progress > x) {
        [path addLineToPoint:CGPointMake(self.frame.size.width*self.progress, 0)];
//    }
    [path closePath];
    
//    progressPath = path;
    progressLayer.path = path.CGPath;
}

- (void)setDash
{
    if (dashs.count > 0) {
        
        UIBezierPath *path = [[UIBezierPath alloc] init];
        
        for (NSInteger i = 0; i < dashs.count; i++) {
            
            CGFloat line = self.frame.size.width*[dashs[i] floatValue];
            
            [path moveToPoint:CGPointMake(line, 0)];
            [path addLineToPoint:CGPointMake(line+2, 0)];
        }
        [path closePath];
        
        dashLayer.path = path.CGPath;
    }
    else {
        dashLayer.path = nil;
    }
}

- (void)setTouchProgress
{
    UIBezierPath *path = [[UIBezierPath alloc] init];
    [path moveToPoint:CGPointMake(self.progress*self.frame.size.width, 0)];
    [path addLineToPoint:CGPointMake(self.touchProgress*self.frame.size.width, 0)];
    [path closePath];
    
    cropLayer.path = path.CGPath;
}

- (void)setCrop
{
    CGFloat progress_ = 0;
    if (CGPointEqualToPoint(touchedPoint, CGPointZero)) {
        progress_ = _progress;
    }
    else {
        progress_ = _touchProgress;
    }
    
    if (progress_ > 0.01) {
        cropImage.hidden = NO;
    }
    else {
        cropImage.hidden = YES;
    }
    cropImage.frame = CGRectMake(-15+self.frame.size.width*progress_, 0, self.frame.size.height, self.frame.size.height);
}

- (void)setProgressWidth:(CGFloat)progressWidth
{
    _progressWidth = progressWidth;
    trackLayer.lineWidth = _progressWidth;
    progressLayer.lineWidth = _progressWidth;
    cropLayer.lineWidth = _progressWidth;
    dashLayer.lineWidth = _progressWidth;
    
    CGFloat y = (self.frame.size.height-progressWidth)*0.5;
    
    trackLayer.frame = CGRectMake(0, y, self.frame.size.width, progressWidth);
    progressLayer.frame = CGRectMake(0, y, self.frame.size.width, progressWidth);
    cropLayer.frame = CGRectMake(0, y, self.frame.size.width, progressWidth);
    dashLayer.frame = CGRectMake(0, y, self.frame.size.width, progressWidth);
    
    [self setTrack];
    [self setProgress];
    [self setDash];
}

- (void)setTrackColor:(UIColor *)trackColor
{
    trackLayer.strokeColor = trackColor.CGColor;
}

- (void)setProgressColor:(UIColor *)progressColor
{
    progressLayer.strokeColor = progressColor.CGColor;
}

- (void)setProgress:(CGFloat)progress
{
    [self setProgress:progress animated:NO];
}

- (void)setProgress:(float)progress animated:(BOOL)animated
{
    if (isnan(progress)) {
        progressLayer.path = nil;
        return;
    }
    else if (progress <= 0) {
        progressLayer.path = nil;
        return;
    }
    else if (progress > 1) {
        return;
    }
    
    if (_progress != progress) {
        
        _progress = progress;

        [self setProgress];
        [self setCrop];
        
        if (animated) {
            CABasicAnimation *pathAnimation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
            pathAnimation.duration = 1.0;
            pathAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
            pathAnimation.fromValue = [NSNumber numberWithFloat:0.0f];
            pathAnimation.toValue = [NSNumber numberWithFloat:1.0f];
            pathAnimation.autoreverses = NO;
            [progressLayer addAnimation:pathAnimation forKey:@"strokeEndAnimation"];
        }
    }
}

- (void)setTouchProgress:(CGFloat)touchProgress
{
    if (isnan(touchProgress)) {
        cropLayer.path = nil;
        _touchProgress = 0;
        [self setCrop];
        return;
    }
    else if (touchProgress <= 0) {
        cropLayer.path = nil;
        _touchProgress = 0;
        [self setCrop];
        return;
    }
    else if (touchProgress > self.progress) {
        return;
    }
    
    if (_touchProgress != touchProgress) {
        _touchProgress = touchProgress;
        
        [self setTouchProgress];
        [self setCrop];
    }
}

- (void)insertDash:(CGFloat)progressDash
{
    if (progressDash == 0) {
        return;
    }
    
    [dashs addObject:[NSNumber numberWithFloat:progressDash]];
    
//    NSLog(@"dashs-->%@",dashs.description);
    
    [self setDash];
}

- (void)reset
{
    [dashs removeAllObjects];
    self.progress = 0;
}

- (void)cropPan:(UIPanGestureRecognizer *)ges
{
    if (self.isRecording) {
        return;
    }
    
    CGPoint point = [ges translationInView:cropImage];

    CGFloat x = point.x+touchedPoint.x;
    
    if (ges.state == UIGestureRecognizerStateBegan) {

        touchedPoint = cropImage.center;
    }
    if (ges.state == UIGestureRecognizerStateChanged) {
        
        if (x <= 10) {
            return;
        }
        
        self.touchProgress = x/self.frame.size.width;
    }
    else if (ges.state == UIGestureRecognizerStateEnded || ges.state == UIGestureRecognizerStateCancelled){
    
        NSMutableArray *dashs_ = dashs.mutableCopy;
        [dashs_ insertObject:[NSNumber numberWithFloat:0] atIndex:0];
        [dashs_ addObject:[NSNumber numberWithFloat:self.progress]];

        CGFloat dashProgross = 0;
       
        NSInteger i = 0;
        for (NSNumber *temp in dashs_) {
            if (x <= temp.doubleValue*self.frame.size.width) {
                
                NSNumber *temp_ = dashs_[i-1];
                
                CGPoint point1 = CGPointMake(temp_.doubleValue*self.frame.size.width, 0);
                CGPoint point2 = CGPointMake(temp.doubleValue*self.frame.size.width, 0);
                
                if (fabs(point1.x-x) <= fabs(point2.x-x)) {
                    dashProgross = temp_.doubleValue;
                }
                else {
                    dashProgross = temp.doubleValue;
                }
                
                break;
            }
            i++;
        }
        
        for (NSNumber *temp2 in dashs_) {
            if (x <= temp2.doubleValue*self.frame.size.width) {
                if ([dashs containsObject:temp2]) {
                    [dashs removeObject:temp2];
                }
            }
        }
        
        
        [self setDash];
        
        self.progress = dashProgross;
        self.touchProgress = dashProgross;

        touchedPoint = CGPointZero;
        
        if (_seekToProgress) {
            _seekToProgress(dashProgross);
        }
    }
}

@end
