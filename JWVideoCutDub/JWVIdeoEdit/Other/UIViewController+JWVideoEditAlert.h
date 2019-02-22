//
//  UIViewController+JWVideoEditAlert.h
//  JWVideoEdit
//
//  Created by 张竟巍 on 2018/8/1.
//  Copyright © 2018年 ACAA. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIViewController (JWVideoEditAlert)


/**
 alert提醒

 @param message message
 @param surehandler 确定
 @param cancelhandler 取消
 */
- (void)showMyAlertWithMessage:(NSString *)message hanler:(void(^)(void))surehandler cancel:(void(^)(void))cancelhandler;



@end
