//
//  CLCameraAuthorizationHelper.h
//  RuShanChuXing
//
//  Created by CardLan on 2018/5/31.
//  Copyright © 2018年 CardLan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>

@interface CLCameraAuthorizationHelper : NSObject

+ (CLCameraAuthorizationHelper *)shareManager;

+ (NSInteger)photoAuthorizationStatus;
+ (NSInteger)mediaAudioAuthorizationStatus:(AVMediaType)mediaType;
- (void)requestAuthorizationWithType:(NSString *)type Completion:(void (^)(void))completion;

@end
