//
//  ViewController.m
//  XWCaptureCamera
//
//  Created by zengchao on 15/10/27.
//  Copyright © 2015年 com.xweisoft.test. All rights reserved.
//

#import "ViewController.h"
#import "XWCaptureViewController.h"

@interface ViewController ()<XWCaptureViewControllerDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}


- (IBAction)gotoCapture:(id)sender
{
    if ([XWCaptureViewController checkStatusOk]) {
        XWCaptureViewController *next = [[XWCaptureViewController alloc] init];
        next.watermark = [UIImage imageNamed:@"logo_test"];
        next.delegate = self;
        [self presentViewController:next animated:YES completion:NULL];
    }

}

- (BOOL)shouldCaptureViewControllerOutputInAlbum:(XWCaptureViewController *)target
{
    return YES;
}

- (void)captureViewControllerOutput:(XWCaptureViewController *)target file:(NSString *)filepath
{
    UIAlertView *alert  =[[UIAlertView alloc] initWithTitle:filepath message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
}

- (void)captureViewControllerCancel:(XWCaptureViewController *)target
{

}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
