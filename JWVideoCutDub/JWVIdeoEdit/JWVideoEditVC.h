//
//  JWVideoEditVC.h
//  JWVideoEdit
//
//  Created by 张竟巍 on 2018/7/31.
//  Copyright © 2018年 ACAA. All rights reserved.
// 视频剪辑

#import <UIKit/UIKit.h>

typedef void(^CutVideoBlock)(NSURL * outputUrl);

@interface JWVideoEditVC : UIViewController

+ (void)presentFromViewController:(UIViewController *)viewController url:(NSURL *)url completion:(CutVideoBlock)cutBlock;

@end
