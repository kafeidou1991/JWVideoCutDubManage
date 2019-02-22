//
//  JWAudioEditManage.h
//  JWVideoEdit
//
//  Created by 张竟巍 on 2018/8/6.
//  Copyright © 2018年 ACAA. All rights reserved.
// 音视频管理

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

//录音管理 合并语音视频文件

@interface JWAudioEditManage : NSObject

+ (instancetype)shareInstance;

@property (nonatomic, strong) AVAudioRecorder * recorder;
/**
 检查录音权限

 @param handler 返回
 */
- (void)checkPermissionCompletionHandler:(void (^)(BOOL granted))handler;
/**
 开始录音
 */
- (void)startAudioRecorder;
/**
 暂停录音
 */
- (void)pauseAudioRecorder;

/**
 结束录音
 */
- (void)stopAudioRecorder;


/**
 获取录音路径

 @return path
 */
- (NSString *)getAudioPath;

- (void)play;

@end
