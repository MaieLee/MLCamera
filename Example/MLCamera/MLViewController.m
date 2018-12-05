//
//  MLViewController.m
//  MLCamera
//
//  Created by MaieLee on 12/04/2018.
//  Copyright (c) 2018 MaieLee. All rights reserved.
//

#import "MLViewController.h"
#import "MyCustomCameraViewController.h"

@interface MLViewController ()

@end

@implementation MLViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    MyCustomCameraViewController *myCustomCamera = [[MyCustomCameraViewController alloc] init];
    myCustomCamera.cameraFinishBlock = ^(BOOL isTakePic, UIImage *showImage, NSURL *videoURL) {
        
    };
    [self presentViewController:myCustomCamera animated:YES completion:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
