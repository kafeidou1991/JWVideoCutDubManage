//
//  UIViewController+JWVideoEditAlert.m
//  JWVideoEdit
//
//  Created by 张竟巍 on 2018/8/1.
//  Copyright © 2018年 ACAA. All rights reserved.
//

#import "UIViewController+JWVideoEditAlert.h"

@implementation UIViewController (JWVideoEditAlert)


- (void)showMyAlertWithMessage:(NSString *)message hanler:(void(^)(void))surehandler cancel:(void(^)(void))cancelhandler{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *sureAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if (surehandler) {
            surehandler();
        }
    }];
    [alertController addAction:sureAction];
    
    if (cancelhandler) {
        UIAlertAction *cancleAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            cancelhandler();
        }];
        [alertController addAction:cancleAction];
    }
    
    [self presentViewController:alertController animated:YES completion:nil];
}


@end
