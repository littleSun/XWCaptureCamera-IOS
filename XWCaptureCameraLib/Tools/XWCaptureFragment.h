//
//  XWCaptureFragment.h
//  XWCaptureCamera
//
//  Created by zengchao on 15/11/4.
//  Copyright © 2015年 com.xweisoft.*. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface XWCaptureFragment : NSObject

@property (nonatomic ,strong) NSURL *url;

@property (nonatomic ,assign) CGFloat duraton;

@property (nonatomic ,strong) AVURLAsset *asset;

@end
