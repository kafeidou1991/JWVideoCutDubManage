//
//  JWHudLoadView.m
//  JWVideoCutDub
//
//  Created by 张竟巍 on 2019/2/21.
//  Copyright © 2019 张竟巍. All rights reserved.
//

#import "JWHudLoadView.h"
#import "MBProgressHUD.h"
#import "AppDelegate.h"

@implementation JWHudLoadView {
    MBProgressHUD * _mbProgressHud;
}

- (void)hudShow:(UIView *)inView msg:(NSString *)msgText{
    if (_mbProgressHud == nil) {
        _mbProgressHud = [MBProgressHUD showHUDAddedTo:inView animated:YES];
    }
    _mbProgressHud.contentColor = [UIColor whiteColor];
    _mbProgressHud.bezelView.color = [UIColor blackColor];
    _mbProgressHud.label.text = msgText;
    _mbProgressHud.animationType = MBProgressHUDAnimationZoom;
    [_mbProgressHud showAnimated:YES];
}

- (void)hudclose{
    if (_mbProgressHud) {
        [_mbProgressHud removeFromSuperview];
        [_mbProgressHud hideAnimated:NO];
        _mbProgressHud = nil;
    }
}


+ (void) alertMessage:(NSString*)msg
{
    AppDelegate *app = (AppDelegate *)[UIApplication sharedApplication].delegate;
    UIWindow *win = app.window;
    MBProgressHUD *HUD = (MBProgressHUD *)[win viewWithTag:8012];
    if(HUD==nil){
        HUD =  [[MBProgressHUD alloc] initWithView:win];
        
        HUD.tag = 8012;
        HUD.mode = MBProgressHUDModeText;
        [win addSubview:HUD];
        HUD.removeFromSuperViewOnHide = YES;
        HUD.contentColor = [UIColor whiteColor];
        HUD.bezelView.color = [UIColor blackColor];
    }
    HUD.label.text = msg;
    [HUD showAnimated:YES];
    dispatch_async(dispatch_get_main_queue(), ^{
        [HUD hideAnimated:YES afterDelay:1.5f];
    });
}



@end
