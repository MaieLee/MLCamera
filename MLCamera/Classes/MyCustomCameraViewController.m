//
//  CLCustomCameraViewController.m
//  CLBangKeHui
//
//  Created by CardLan on 2018/5/25.
//  Copyright © 2018年 CardLan. All rights reserved.
//

#import "MyCustomCameraViewController.h"
#import "GPUImage.h"
#import "Masonry.h"
#import "CLCameraButtonView.h"
#import "CLCameraAuthorizationHelper.h"

@interface MyCustomCameraViewController ()<UIGestureRecognizerDelegate,CAAnimationDelegate,UIAlertViewDelegate>
{
    NSString *pathToMovie;
    GPUImageMovieWriter *movieWriter;
}
@property (nonatomic, strong) GPUImageView *gpuImageView;
@property (nonatomic, strong) GPUImageStillCamera *gpuStillCamera;
@property (nonatomic, strong) GPUImageVideoCamera *gpuVideoCamera;
@property (nonatomic, strong) GPUImageSaturationFilter *filter;
@property (nonatomic, strong) UILabel *infoLabel;
@property (nonatomic, strong) CLCameraButtonView *cameraButton;
@property (nonatomic, strong) UIButton *backButton;//返回按钮
@property (nonatomic, strong) UIButton *cancelButton;//取消当前按钮
@property (nonatomic, strong) UIButton *selectButton;//选择当前按钮
@property (nonatomic, assign) BOOL isTakeVideo;
@property (nonatomic, strong) UIImage *showImage;
@property (nonatomic, strong) NSURL *videoURL;
@property (strong, nonatomic) AVPlayer *myPlayer;//播放器
@property (strong, nonatomic) AVPlayerItem *item;//播放单元
@property (strong, nonatomic) AVPlayerLayer *playerLayer;//播放界面（layer）
@property (nonatomic, strong) UIView *playVideoView;
@property (nonatomic, assign) BOOL isHadLoadVideoCamera;
@property (nonatomic, assign) BOOL isRefuseAccessAudio;//拒绝访问麦克风
@property (nonatomic, assign) BOOL isHasInitCamera;
@end

@implementation MyCustomCameraViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    [self checkoutCameraAuthority];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}

- (void)checkoutCameraAuthority{
    AVAuthorizationStatus authStatus = [CLCameraAuthorizationHelper mediaAudioAuthorizationStatus:AVMediaTypeVideo];
    
    if (authStatus == AVAuthorizationStatusDenied) {
        NSString *app_Name = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
        NSString *message = [NSString stringWithFormat:@"%@需要访问您的相机,请在设置/隐私/相机中允许访问相机",app_Name];
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"无法访问相机" message:message delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"设置", nil];
        alert.tag = 1001;
        [alert show];
    }else if(authStatus == AVAuthorizationStatusNotDetermined){
        [[CLCameraAuthorizationHelper shareManager] requestAuthorizationWithType:AVMediaTypeVideo Completion:^{
            [self checkoutCameraAuthority];
        }];
    }else{
        [self setUpUI];
        [self addAutoLayout];
        [self preFilter];
        [self setUpStillCamera];
        
        [self addNotification];
    }
}

- (void)setUpUI{
    self.gpuImageView = [[GPUImageView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.gpuImageView.fillMode = kGPUImageFillModePreserveAspectRatioAndFill;
    [self.view addSubview:self.gpuImageView];
    
    self.playVideoView = [[UIView alloc] initWithFrame:self.gpuImageView.frame];
    [self.view addSubview:self.playVideoView];
    self.playVideoView.backgroundColor = [UIColor colorWithWhite:1 alpha:0];
    self.playVideoView.hidden = YES;
    
    NSInteger scale = [[UIScreen mainScreen] scale];
    NSBundle *currentBundle = [NSBundle bundleForClass:[self class]];
    NSString *imageName = [NSString stringWithFormat:@"arrow_down_shoot@%dx.png",scale];
    NSString *path = [currentBundle pathForResource:imageName ofType:nil inDirectory:@"MLCamera.bundle"];
    
    _backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_backButton setImage:[UIImage imageWithContentsOfFile:path] forState:UIControlStateNormal];
    [self.view addSubview:_backButton];
    [_backButton addTarget:self action:@selector(backAction) forControlEvents:UIControlEventTouchUpInside];
    
    imageName = [NSString stringWithFormat:@"back_shoot@%dx.png",scale];
    path = [currentBundle pathForResource:imageName ofType:nil inDirectory:@"MLCamera.bundle"];
    
    _cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_cancelButton setImage:[UIImage imageWithContentsOfFile:path] forState:UIControlStateNormal];
    [self.view addSubview:_cancelButton];
    _cancelButton.hidden = YES;
    [_cancelButton addTarget:self action:@selector(cancelAction) forControlEvents:UIControlEventTouchUpInside];
    
    imageName = [NSString stringWithFormat:@"confirm_shoot@%dx.png",scale];
    path = [currentBundle pathForResource:imageName ofType:nil inDirectory:@"MLCamera.bundle"];
    _selectButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_selectButton setImage:[UIImage imageWithContentsOfFile:path] forState:UIControlStateNormal];
    [self.view addSubview:_selectButton];
    _selectButton.hidden = YES;
    [_selectButton addTarget:self action:@selector(selectAction) forControlEvents:UIControlEventTouchUpInside];
    
    _infoLabel = [UILabel new];
    _infoLabel.textColor = [UIColor whiteColor];
    _infoLabel.text = @"轻触拍照，按住摄像";
    [_infoLabel sizeToFit];
    _infoLabel.font = [UIFont systemFontOfSize:16];
    _infoLabel.alpha = 0.0;
    [self.view addSubview:_infoLabel];
    
    typeof(self) __weak weakSelf = self;
    _cameraButton = [[CLCameraButtonView alloc] initWithFrame:CGRectMake(0, 0, 87, 87)];
    [self.view addSubview:_cameraButton];
    _cameraButton.takePicture = ^{
        [weakSelf takePicture];
    };
    _cameraButton.takeVideo = ^(NSInteger cameraStatus) {
        if (cameraStatus == 0) {
            [weakSelf preVideoRecording];
        }else if (cameraStatus == 1) {
            [weakSelf startVideoRecording];
        }else if (cameraStatus == 2) {
            [weakSelf stopVideoRecording];
        }else if(cameraStatus == 3){
            //还没开始录制长按手势已经结束
            weakSelf.backButton.hidden = NO;
            [weakSelf.gpuVideoCamera stopCameraCapture];
            [weakSelf setUpStillCamera];
        }
    };
    _cameraButton.center = CGPointMake(self.view.center.x, self.view.frame.size.height-97.5);
}

- (void)addAutoLayout
{
    [self.gpuImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.and.right.and.bottom.and.top.equalTo(self.view);
    }];
    [self.backButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(58);
        make.height.mas_equalTo(34);
        make.left.mas_equalTo(43.5);
        make.bottom.mas_equalTo(-81.5);
    }];
    [self.cameraButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.and.height.mas_equalTo(87);
        make.centerX.equalTo(self.view);
        make.centerY.equalTo(self.backButton);
    }];
    [self.infoLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.bottom.equalTo(self.cameraButton.mas_top).offset(-30);
    }];
    [self.cancelButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.cameraButton);
        make.width.and.height.mas_equalTo(self.cameraButton);
    }];
    [self.selectButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.cameraButton);
        make.width.and.height.mas_equalTo(self.cameraButton);
    }];
}

- (void)preFilter{
    self.filter = [[GPUImageSaturationFilter alloc] init];
}

- (void)setUpStillCamera{
    self.isTakeVideo = NO;
    [self.gpuStillCamera removeAllTargets];
    [self.filter removeAllTargets];
    
    [self.gpuStillCamera addTarget:self.filter];
    [self.filter addTarget:self.gpuImageView];
    dispatch_async(dispatch_get_global_queue(0,0), ^{
        [self.gpuStillCamera startCameraCapture];
        if (!self.isHasInitCamera) {
            self.isHasInitCamera = YES;
            dispatch_async(dispatch_get_main_queue(), ^{
                [UIView animateWithDuration:0.5 animations:^{
                    self.infoLabel.alpha = 0.9;
                } completion:^(BOOL finished) {
                    [UIView animateWithDuration:2.5 animations:^{
                        self.infoLabel.alpha = 1.0;
                    } completion:^(BOOL finished) {
                        [self.infoLabel removeFromSuperview];
                    }];
                }];
            });
        }
    });
}

- (GPUImageStillCamera *)gpuStillCamera{
    if (_gpuStillCamera == nil) {
        _gpuStillCamera = [[GPUImageStillCamera alloc] initWithSessionPreset:AVCaptureSessionPresetHigh cameraPosition:AVCaptureDevicePositionBack];
        _gpuStillCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
        _gpuStillCamera.horizontallyMirrorFrontFacingCamera = YES;
        _gpuStillCamera.horizontallyMirrorRearFacingCamera  = NO;
    }
    
    return _gpuStillCamera;
}

- (void)setUpVideoCamera{
    self.isHadLoadVideoCamera = YES;
    [self.gpuVideoCamera removeAllTargets];
    [self.filter removeAllTargets];
    
    [self.gpuVideoCamera addTarget:self.filter];
    [self.filter addTarget:self.gpuImageView];
    
    dispatch_async(dispatch_get_global_queue(0,0), ^{
        [self.gpuVideoCamera startCameraCapture];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.cameraButton startRecord];
        });
    });
}

- (GPUImageVideoCamera *)gpuVideoCamera{
    if (_gpuVideoCamera == nil) {
        _gpuVideoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPresetHigh cameraPosition:AVCaptureDevicePositionBack];
        _gpuVideoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
        _gpuVideoCamera.horizontallyMirrorFrontFacingCamera = YES;
        _gpuVideoCamera.horizontallyMirrorRearFacingCamera  = NO;
        if (!self.isRefuseAccessAudio) {
            [_gpuVideoCamera addAudioInputsAndOutputs];
        }
    }
    
    return _gpuVideoCamera;
}

- (void)backAction
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)cancelAction
{
    if (self.isTakeVideo) {
        [self.gpuVideoCamera stopCameraCapture];
        [self setUpStillCamera];
    }else{
        [self.gpuStillCamera startCameraCapture];
    }
    
    self.backButton.hidden = NO;
    self.cancelButton.hidden = YES;
    self.selectButton.hidden = YES;
    self.cameraButton.hidden = NO;
    self.cancelButton.transform = CGAffineTransformMakeTranslation(0, 0);
    self.selectButton.transform = CGAffineTransformMakeTranslation(0, 0);
    
    [self.myPlayer pause];
    [self.playerLayer removeFromSuperlayer];
    self.playVideoView.hidden = YES;
}

- (void)selectAction{
    if (self.isTakeVideo) {
        [self videoTranscoding];
        
        [self.myPlayer pause];
        self.myPlayer = nil;
        [self.playerLayer removeFromSuperlayer];
    } else {
        if (self.cameraFinishBlock) {
            self.cameraFinishBlock(!self.isTakeVideo, self.showImage, self.videoURL);
        }
    }
    
    [self backAction];
}

// 压缩处理
- (void)videoTranscoding {
    AVURLAsset *avAsset = [AVURLAsset URLAssetWithURL:self.videoURL  options:nil];
    //    NSLog(@"%@-------%@", pathToMovie, self.videoURL);
    AVAssetExportSession *exportSession =  [AVAssetExportSession exportSessionWithAsset:avAsset presetName:AVAssetExportPresetMediumQuality];
    exportSession.shouldOptimizeForNetworkUse = YES;
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyyMMddHHmmss";
    NSString *str = [formatter stringFromDate:[NSDate date]];
    NSString* path = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mp4", str]];
    
    exportSession.outputURL = [NSURL fileURLWithPath:path];
    exportSession.outputFileType = AVFileTypeMPEG4;
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        if ([exportSession status] == AVAssetExportSessionStatusCompleted) {
            [self clearMovieFromDoucments];
            self.videoURL = [NSURL fileURLWithPath:path];
        } else {
            //            NSLog(@"转换失败,值为:%li,可能的原因:%@",(long)[exportSession status],[[exportSession error] localizedDescription]);
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.cameraFinishBlock) {
                self.cameraFinishBlock(!self.isTakeVideo, self.showImage, self.videoURL);
            }
        });
    }];
}

// 转码成功后删除原沙盒的视频
- (void)clearMovieFromDoucments {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtPath:pathToMovie error:nil];
}

- (void)takePicture {
    self.videoURL = nil;
    self.backButton.hidden = YES;
    [self.gpuStillCamera capturePhotoAsImageProcessedUpToFilter:self.filter withCompletionHandler:^(UIImage *processedImage, NSError *error) {
        [self.gpuStillCamera stopCameraCapture];
        self.showImage = processedImage;
        
        self.cancelButton.hidden = NO;
        self.selectButton.hidden = NO;
        self.cameraButton.hidden = YES;
        [UIView animateWithDuration:0.2 animations:^{
            self.cancelButton.transform = CGAffineTransformMakeTranslation(-69, 0);
            self.selectButton.transform = CGAffineTransformMakeTranslation(69, 0);
        } completion:^(BOOL finished) {
            
        }];
    }];
}

- (void)preVideoRecording
{
    if (self.isRefuseAccessAudio) {
        self.backButton.hidden = YES;
        [self.gpuStillCamera removeAllTargets];
        [self setUpVideoCamera];
    }else{
        AVAuthorizationStatus authStatus = [CLCameraAuthorizationHelper mediaAudioAuthorizationStatus:AVMediaTypeAudio];
        
        if (authStatus == AVAuthorizationStatusDenied) {
            NSString *app_Name = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
            NSString *message = [NSString stringWithFormat:@"%@需要访问您的麦克风,请在设置/隐私/麦克风中启用麦克风",app_Name];
            UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"无法访问麦克风" message:message delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"设置", nil];
            alert.tag = 1002;
            [alert show];
        }else if(authStatus == AVAuthorizationStatusNotDetermined){
            [[CLCameraAuthorizationHelper shareManager] requestAuthorizationWithType:AVMediaTypeAudio Completion:nil];
        }else{
            self.backButton.hidden = YES;
            [self.gpuStillCamera removeAllTargets];
            [self setUpVideoCamera];
        }
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        if (alertView.tag == 1001) {
            [self backAction];
            return;
        }
        if (alertView.tag == 1002) {
            self.isRefuseAccessAudio = YES;
            return;
        }
    }
    if (buttonIndex == 1) {
        NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
        if ([ [UIApplication sharedApplication] canOpenURL:url])
        {
            [[UIApplication sharedApplication] openURL:url];
        }
    }
}

- (void)startVideoRecording
{
    self.isTakeVideo = YES;
    
    pathToMovie = [NSTemporaryDirectory() stringByAppendingPathComponent:@"Movie.mp4"];
    // If a file already exists, AVAssetWriter won't let you record new frames, so delete the old movie
    unlink([pathToMovie UTF8String]);
    NSURL *movieURL = [NSURL fileURLWithPath:pathToMovie];
    movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:movieURL size:CGSizeMake(720.0, 1280.0)];
    
    movieWriter.encodingLiveVideo = YES;
    movieWriter.shouldPassthroughAudio = YES;
    [self.filter addTarget:movieWriter];
    self.gpuVideoCamera.audioEncodingTarget = movieWriter;
    [movieWriter startRecording];
}

- (void)stopVideoRecording
{
    if (!self.isTakeVideo) {
        return;
    }
    self.gpuVideoCamera.audioEncodingTarget = nil;
    
    [movieWriter finishRecordingWithCompletionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            self.playVideoView.hidden = NO;
            NSURL *movieURL = [NSURL fileURLWithPath:self->pathToMovie];
            self.item = [[AVPlayerItem alloc] initWithURL:movieURL];
            self.myPlayer = [AVPlayer playerWithPlayerItem:self.item];
            self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.myPlayer];
            self.playerLayer.frame = self.view.frame;
            self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
            [self.playVideoView.layer addSublayer:self.playerLayer];
            [self.myPlayer play];
            
            self.cancelButton.hidden = NO;
            self.selectButton.hidden = NO;
            self.cameraButton.hidden = YES;
            [UIView animateWithDuration:0.2 animations:^{
                self.cancelButton.transform = CGAffineTransformMakeTranslation(-69, 0);
                self.selectButton.transform = CGAffineTransformMakeTranslation(69, 0);
            } completion:^(BOOL finished) {
                
            }];
            
            self.showImage = [self firstFrameWithVideoURL:self->pathToMovie size:self.gpuImageView.frame.size];
            self.videoURL = movieURL;
            
            [self.gpuVideoCamera stopCameraCapture];
            [self.cameraButton finishSaveVideo];
        });
    }];
    
    [self.filter removeTarget:movieWriter];
}

#pragma mark ---- 获取视频第一帧
- (UIImage *)firstFrameWithVideoURL:(NSString *)urlString size:(CGSize)size
{
    NSURL *url = [NSURL fileURLWithPath:urlString];
    
    NSDictionary *opts = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
    AVURLAsset *urlAsset = [AVURLAsset URLAssetWithURL:url options:opts];
    AVAssetImageGenerator *generator = [AVAssetImageGenerator assetImageGeneratorWithAsset:urlAsset];
    generator.appliesPreferredTrackTransform = YES;
    generator.maximumSize = CGSizeMake(size.width, size.height);
    NSError *error = nil;
    CGImageRef img = [generator copyCGImageAtTime:CMTimeMake(0, 10) actualTime:NULL error:&error];
    {
        return [UIImage imageWithCGImage:img];
    }
    return nil;
}

#pragma mark ---- 循环播放视频
/**
 *  添加播放器通知，通过AVPlayerItemDidPlayToEndTimeNotification字段判断播放器播放情况
 */
-(void)addNotification{
    //给AVPlayerItem添加播放完成通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackFinished:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.myPlayer.currentItem];
}

-(void)removeNotification{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

/**
 *  播放完成通知
 *
 *  @param notification 通知对象
 */
-(void)playbackFinished:(NSNotification *)notification{
    [self.myPlayer seekToTime:CMTimeMake(0, 1)];
    [self.myPlayer play];
}

- (void)dealloc
{
    [self.gpuStillCamera removeAllTargets];
    [self.gpuStillCamera stopCameraCapture];
    if (self.isHadLoadVideoCamera) {
        [self.gpuVideoCamera stopCameraCapture];
        [self.gpuVideoCamera removeInputsAndOutputs];
        [self.gpuVideoCamera removeAllTargets];
    }
    
    [self removeNotification];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
