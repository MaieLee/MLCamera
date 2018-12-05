//
//  MyCustomCameraViewController.h
//  MyLee
//
//  Created by MyLee on 2018/5/25.
//  Copyright © 2018年 MyLee. All rights reserved.
//

#import <UIKit/UIKit.h>

//isTakePic:YES，拍照 NO，摄像;showImage:要显示的图片;videoURL:录像文件的地址，isTakePic为NO时不为空
typedef void(^CustomCameraViewBlock) (BOOL isTakePic,UIImage *showImage,NSURL *videoURL);

@interface MyCustomCameraViewController : UIViewController

@property (nonatomic, copy) CustomCameraViewBlock cameraFinishBlock;

@end
