//
//  XWCaptureViewController.m
//  XWCaptureCamera
//
//  Created by zengchao on 15/10/27.
//  Copyright © 2015年 com.xweisoft. All rights reserved.
//

#import "XWCaptureViewController.h"
#import "XWCaptureLayerViewController.h"
#import "UIImage+Capture.h"
#import "XWCaptureHelp.h"

@implementation XWCaptureViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        //
        [self setup];
    }
    return self;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

/**
 @method
 @brief 初始化缺省数据
 @discussion
 @param
 @result
 */
- (void)setup
{
    if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)]) {
        self.modalPresentationCapturesStatusBarAppearance = YES;
        [self setNeedsStatusBarAppearanceUpdate];
    }
    
    _maximumCaptureDuration = 30;
    _option = XWCaptureDefinition_normal;
    
    [[NSFileManager defaultManager] createDirectoryAtPath:[XWCaptureHelp cachePath] withIntermediateDirectories:YES attributes:nil error:nil];
     
    self.view.backgroundColor = [UIColor blackColor];
    
    [self setupNavigationController];
}


- (void)setupNavigationController
{
    XWCaptureLayerViewController *vc = [[XWCaptureLayerViewController alloc] init];
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    
    // Enable iOS 7 back gesture
    if ([nav respondsToSelector:@selector(interactivePopGestureRecognizer)])
    {
        nav.interactivePopGestureRecognizer.enabled  = YES;
        nav.interactivePopGestureRecognizer.delegate = nil;
        nav.delegate = self;
    }
    
    //    nav.delegate = self;
    [nav willMoveToParentViewController:self];
    
    // Set frame origin to zero so that the view will be positioned correctly while in-call status bar is shown
    [nav.view setFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    [self.view addSubview:nav.view];
    [self addChildViewController:nav];
    [nav didMoveToParentViewController:self];
    
    [self naviUI];
}

- (void)dismiss:(id)sender
{
    if (_delegate && [_delegate respondsToSelector:@selector(captureViewControllerCancel:)]) {
        [self.delegate captureViewControllerCancel:self];
    }
    
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)finishPickingAssets:(id)sender
{    
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Accessors

- (UINavigationController *)childNavigationController
{
    return (UINavigationController *)self.childViewControllers.firstObject;
}

- (void)naviUI
{
    NSDictionary *titleTextAttributes_ = [[UINavigationBar appearance] titleTextAttributes];
    NSMutableDictionary *titleTextAttributes = [NSMutableDictionary dictionary];
    if (titleTextAttributes_) {
        [titleTextAttributes addEntriesFromDictionary:titleTextAttributes_];
    }
    [titleTextAttributes setValue:[UIColor whiteColor] forKey:UITextAttributeTextColor];
    [titleTextAttributes setValue:[UIColor clearColor] forKey:UITextAttributeTextShadowColor];
    [titleTextAttributes setValue:[NSValue valueWithUIOffset:UIOffsetMake(0, 0)] forKey:UITextAttributeTextShadowOffset];
    [self.childNavigationController.navigationBar setTitleTextAttributes:titleTextAttributes];
    
    if ([UINavigationBar instancesRespondToSelector:@selector(setShadowImage:)])
    {
        [self.childNavigationController.navigationBar setShadowImage:[[UIImage alloc] init]];
    }
    
    [self.childNavigationController.navigationBar setBackgroundImage:[UIImage imageWithColor:[UIColor blackColor]] forBarMetrics:UIBarMetricsDefault];
}

#pragma mark --Output
- (NSString *)outputFolder
{
    if (!_outputFolder) {
        _outputFolder = [[XWCaptureHelp cachePath] copy];
    }
    return _outputFolder;
}


- (UIColor *)themeColor
{
    if (!_themeColor) {
        _themeColor  = [UIColor greenColor];
    }
    return _themeColor;
}

+ (BOOL)checkStatusOk
{
    BOOL result = NO;
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
        AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
        
        switch (status) {
            case AVAuthorizationStatusAuthorized:
            {
                result = YES;
            }
                break;
            case AVAuthorizationStatusNotDetermined:
            {
                [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                    if(granted){
                        
                    } else {
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"无法使用相机" message:@"请在iPhone的\"设置-隐私-相机\"中允许访问相机" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
                        [alert show];
                    }
                }];
                
                result = YES;
                
                break;
            }
            default:
            {
                NSLog(@"denied");
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"无法使用相机" message:@"请在iPhone的\"设置-隐私-相机\"中允许访问相机" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
                [alert show];
            }
                break;
        }
    }
    else {
        
        if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
            NSLog(@"not determined");
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"无法使用相机" message:@"请在iPhone的\"设置-隐私-相机\"中允许访问相机" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
            [alert show];
        }
        else {
            result = YES;
        }
        
    }
    
    return result;
}

@end
