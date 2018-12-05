//
//  CLCameraButtonView.h
//  MyLee
//
//  Created by MyLee on 2018/5/25.
//  Copyright © 2018年 MyLee. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^TakePictureComplete) (void);
typedef void(^TakeVideoComplete) (NSInteger cameraStatus);//0:pre 1:start 2:end

@interface CLCameraButtonView : UIView
@property (nonatomic, assign) CGFloat progress;
@property (nonatomic, copy) TakePictureComplete takePicture;
@property (nonatomic, copy) TakeVideoComplete takeVideo;

- (void)startRecord;
- (void)finishSavePic;
- (void)finishSaveVideo;
@end
