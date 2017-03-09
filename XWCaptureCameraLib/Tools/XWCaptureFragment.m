//
//  XWCaptureFragment.m
//  XWCaptureCamera
//
//  Created by zengchao on 15/11/4.
//  Copyright © 2015年 com.xweisoft.*. All rights reserved.
//

#import "XWCaptureFragment.h"
#import "XWCaptureHelp.h"

@implementation XWCaptureFragment

- (id)init
{
    if (self = [super init]) {
        //...
        NSString *path = [NSString stringWithFormat:@"%@/%@_video.mov",[XWCaptureHelp cachePath],[NSUUID UUID].UUIDString];
        self.url = [NSURL fileURLWithPath:path];
    }
    return self;
}

- (AVURLAsset *)asset
{
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.url.path]) {
        NSDictionary *opts = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
        return [AVURLAsset URLAssetWithURL:self.url options:opts];
    }
    return nil;
}


@end
