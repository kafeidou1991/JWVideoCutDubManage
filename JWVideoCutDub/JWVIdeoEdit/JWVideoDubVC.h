//
//  JWVideoDubVC.h
//  JWVideoEdit
//
//  Created by 张竟巍 on 2018/8/1.
//  Copyright © 2018年 ACAA. All rights reserved.
// 配音

#import <UIKit/UIKit.h>

typedef void(^DubVideoBlock)(NSURL * outputUrl);

@interface JWVideoDubVC : UIViewController

+ (void)presentFromViewController:(UIViewController *)viewController url:(NSURL *)url completion:(DubVideoBlock)dubBlock;

@end
