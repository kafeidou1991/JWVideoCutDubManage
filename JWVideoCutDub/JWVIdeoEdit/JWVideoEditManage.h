//
//  JWVideoCutManage.h
//  JWVideoEdit
//
//  Created by 张竟巍 on 2018/8/1.
//  Copyright © 2018年 ACAA. All rights reserved.
// 剪辑管理

#import <AVFoundation/AVFoundation.h>

//剪辑时长
typedef struct TimeRange {
    CGFloat location;
    CGFloat length;
} TimeRange;

@interface JWVideoEditManage : NSObject
/**
 剪辑视频

 @param videoUrl 路径
 @param videoRange 剪辑范围
 @param completionHandle 完成
 */
+ (void)captureVideoWithVideoUrl:(NSURL *)videoUrl
                       timeRange:(TimeRange)videoRange
                      completion:(void (^)(NSURL * outPutUrl,NSError * error))completionHandle;

/**
 去除视频声道声音

 @param videoUrl 路径
 @param completionHandle 完成
 */
+ (void)deleteVideoAudio:(NSURL *)videoUrl
              completion:(void (^)(NSURL * outPutUrl,NSError * error))completionHandle;
/**
 合成配音视频

 @param videoUrl 无声视频
 @param audioUrl 声音路径
 @param completionHandle nil
 */
+ (void)addBackgroundMiusicWithVideoUrlStr:(NSURL *)videoUrl
                                  audioUrl:(NSURL *)audioUrl
                                completion:(void(^)(NSURL * outPutUrl,NSError * error))completionHandle;

/**
 转换视频格式，导出视频
 
 @param inputURL 输入源
 @param handler 回调
 */
+ (void)exportSessionVideoWithInputURL:(NSURL*)inputURL
                                   completion:(void(^)(NSURL * outPutUrl,NSError * error))completionHandle;


/**
 相册读取之后照片路径，内部会将相册内部的视频缓存至沙盒路径

 @param info imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
 @param result 缓存路径
 */
+ (void)getVideoLocalPath:(NSDictionary<NSString *,id> *)info
                   result:(void(^)(NSURL * videoURL))result;

/**
 获取视频缩略图
 
 @param url url
 */
+ (CGImageRef)thumbnailImageRequestWithURL:(NSURL *)url;

/**
 清楚剪辑视频路径
 */
+ (void)clearCutVideoCache;

@end
