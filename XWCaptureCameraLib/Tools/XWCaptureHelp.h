//
//  XWCaptureHelp.h
//  XWCaptureCamera
//
//  Created by zengchao on 15/10/30.
//  Copyright © 2015年 com.xweisoft.*. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface XWCaptureHelp : NSObject

+ (AVCaptureDevice *)captureDeviceForPosition:(AVCaptureDevicePosition)position;
+ (AVCaptureConnection *)connectionWithMediaType:(NSString *)mediaType fromConnections:(NSArray *)connections;
+ (AVCaptureDevice *)audioDevice;

+ (CGFloat)angleOffsetFromPortraitOrientationToOrientation:(AVCaptureVideoOrientation)orientation;

+ (uint64_t)availableDiskSpaceInBytes;

+ (NSString *)cachePath;

@end
