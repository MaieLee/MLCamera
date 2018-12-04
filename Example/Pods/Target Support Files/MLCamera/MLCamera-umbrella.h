#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "MyCustomCameraViewController.h"
#import "CLCameraAuthorizationHelper.h"
#import "CLCameraButtonView.h"
#import "CLCircleView.h"
#import "CLSolidCircleView.h"

FOUNDATION_EXPORT double MLCameraVersionNumber;
FOUNDATION_EXPORT const unsigned char MLCameraVersionString[];

