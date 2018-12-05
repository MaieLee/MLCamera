//
//  CLCameraAuthorizationHelper.m
//  RuShanChuXing
//
//  Created by MyLee on 2018/5/31.
//  Copyright © 2018年 MyLee. All rights reserved.
//

#import "CLCameraAuthorizationHelper.h"

@implementation CLCameraAuthorizationHelper

+ (CLCameraAuthorizationHelper *)shareManager
{
    static CLCameraAuthorizationHelper *shareCLCameraAuthorizationHelperInstance = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        shareCLCameraAuthorizationHelperInstance = [[self alloc] init];
    });
    
    return shareCLCameraAuthorizationHelperInstance;
}

+ (NSInteger)photoAuthorizationStatus {
    return [PHPhotoLibrary authorizationStatus];
}

+ (NSInteger)mediaAudioAuthorizationStatus:(AVMediaType)mediaType {
    return [AVCaptureDevice authorizationStatusForMediaType:mediaType];
}

- (void)requestAuthorizationWithType:(NSString *)type Completion:(void (^)(void))completion {
    void (^callCompletionBlock)(void) = ^(){
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion();
            }
        });
    };
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if ([type isEqualToString:@"photo"]) {
            [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
                callCompletionBlock();
            }];
        }else{
            [AVCaptureDevice requestAccessForMediaType:type completionHandler:^(BOOL granted) {
                callCompletionBlock();
            }];
        }
    });
}

@end
