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
@property (strong, nonatomic) UIImageView *showImageView;
@end

@implementation MLViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.view.backgroundColor = [UIColor whiteColor];
    self.showImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 60, self.view.frame.size.width*2/3, self.view.frame.size.height*2/3)];
    [self.view addSubview:self.showImageView];
    self.showImageView.center = CGPointMake(self.view.center.x, self.showImageView.center.y);
    
    UIButton *takeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [takeBtn setTitle:@"使用相机" forState:UIControlStateNormal];
    [takeBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [takeBtn addTarget:self action:@selector(takePhotoAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:takeBtn];
    takeBtn.frame = CGRectMake(self.showImageView.frame.origin.x, self.showImageView.frame.origin.y+self.showImageView.frame.size.height+50, self.showImageView.frame.size.width, 90);
    
    
}

- (void)takePhotoAction:(id)sender{
    __weak typeof(self) weakSelf = self;
    MyCustomCameraViewController *myCustomCamera = [[MyCustomCameraViewController alloc] init];
    myCustomCamera.cameraFinishBlock = ^(BOOL isTakePic, UIImage *showImage, NSURL *videoURL) {
        weakSelf.showImageView.image = showImage;
    };
    [self presentViewController:myCustomCamera animated:YES completion:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
