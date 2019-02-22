//
//  JWHudLoadView.h
//  JWVideoCutDub
//
//  Created by 张竟巍 on 2019/2/21.
//  Copyright © 2019 张竟巍. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@class UIView;
@interface JWHudLoadView : NSObject

/**
 显示页面loading

 @param inView view
 @param msgText 文案
 */
- (void)hudShow:(UIView *)inView msg:(NSString *)msgText;

/**
 取消loading
 */
- (void)hudclose;


/**
 提醒  自动消失

 @param msg <#msg description#>
 */
+ (void) alertMessage:(NSString*)msg;

@end

NS_ASSUME_NONNULL_END
