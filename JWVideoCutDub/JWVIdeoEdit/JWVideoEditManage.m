//
//  JWVideoCutManage.m
//  JWVideoEdit
//
//  Created by 张竟巍 on 2018/8/1.
//  Copyright © 2018年 ACAA. All rights reserved.
//

#import "JWVideoEditManage.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <Photos/Photos.h>
#import "JWHudLoadView.h"

#define kCutVideoPath @"cutDoneVideo.mov"   //剪切的视频文件名
#define kDubVideoPath @"dubVideoPath.mov"   //剪切的视频文件名
#define kMergeVideoPath @"mergeVideoPath.mov"   //剪切的视频文件名
#define kMergeAudioPath @"mergeAudioPath.caf"   //合成视频时将音频转换成caf轨道

#define kTempAssetVideo @"tempAssetVideo.mov"  //相册读取之后沙盒路径

//视频配音录音 、压缩裁剪路径
#define kCachesVideoStorageEdit ({\
NSString * path = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"VideoStorageEdit"];\
if (![[NSFileManager defaultManager]fileExistsAtPath:path]) {\
[[NSFileManager defaultManager]createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];\
}\
(path);\
})

@implementation JWVideoEditManage

//MARK: 检查保存视频权限
+ (void)checkVideoPermissionCompletionHandler:(void (^)(BOOL granted))handler {
    PHAuthorizationStatus permission = [PHPhotoLibrary authorizationStatus];
    if (permission == PHAuthorizationStatusAuthorized) {
        if (handler) {
            handler(YES);
        }
    }else {
        [self resquestUserPermissionCompletionHandler:handler];
    }
}
//请求权限
+ (void)resquestUserPermissionCompletionHandler:(void (^)(BOOL granted))handler {
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        if (status == PHAuthorizationStatusAuthorized) {
            // 通过验证
            dispatch_async(dispatch_get_main_queue(), ^{
                if (handler) {
                    handler(YES);
                }
            });
        }else {
            // 未通过验证
            handler(NO);
        }

    }];
}
//MARK: 剪辑视频
+ (void)captureVideoWithVideoUrl:(NSURL *)videoUrl timeRange:(TimeRange)videoRange completion:(void (^)(NSURL * outPutUrl,NSError * error))completionHandle{
    if (!videoUrl.path || [videoUrl.path isEqualToString:@""] || videoRange.length == NSNotFound) {
        return;
    }
    //AVURLAsset此类主要用于获取媒体信息，包括视频、声音等
    AVURLAsset* videoAsset = [[AVURLAsset alloc] initWithURL:videoUrl options:nil];
    NSArray *tracks = videoAsset.tracks;
    NSLog(@"所有轨道:%@\n",tracks);//打印出所有的资源轨道
    //创建AVMutableComposition对象来添加视频音频资源的AVMutableCompositionTrack
    AVMutableComposition* mixComposition = [AVMutableComposition composition];
    //CMTimeRangeMake(start, duration),start起始时间，duration时长，都是CMTime类型
    //CMTimeMake(int64_t value, int32_t timescale)，返回CMTime，value视频的一个总帧数，timescale是指每秒视频播放的帧数，视频播放速率，（value / timescale）才是视频实际的秒数时长，timescale一般情况下不改变，截取视频长度通过改变value的值
    //CMTimeMakeWithSeconds(Float64 seconds, int32_t preferredTimeScale)，返回CMTime，seconds截取时长（单位秒），preferredTimeScale每秒帧数
    //开始位置startTime
    CMTime startTime = CMTimeMakeWithSeconds(videoRange.location, videoAsset.duration.timescale);
    //截取长度videoDuration
    CMTime videoDuration = CMTimeMakeWithSeconds(videoRange.length, videoAsset.duration.timescale);
    
    CMTimeRange videoTimeRange = CMTimeRangeMake(startTime, videoDuration);
    
    //视频采集compositionVideoTrack 添加视频轨道
    AVVideoComposition * videoComposition = [self addVideoCompositionTrack:mixComposition timeRange:videoTimeRange assert:videoAsset];
    
    //视频声音采集(也可不执行这段代码不采集视频音轨，合并后的视频文件将没有视频原来的声音)
    [self addAudioCompositionTrack:mixComposition timeRange:videoTimeRange assert:videoAsset];
    
    //AVAssetExportSession用于合并文件，导出合并后文件，presetName文件的输出类型
    NSString *outPutPath = [kCachesVideoStorageEdit stringByAppendingPathComponent:kCutVideoPath];
    [self exportVideoSession:mixComposition outPath:outPutPath videoComposition:videoComposition completion:completionHandle];
}
//MARK: 去除视频声道
+ (void)deleteVideoAudio:(NSURL *)videoUrl completion:(void (^)(NSURL * outPutUrl,NSError * error))completionHandle{
    if (!videoUrl.path || [videoUrl.path isEqualToString:@""]) {
        return;
    }
    //AVURLAsset此类主要用于获取媒体信息，包括视频、声音等
    AVURLAsset* videoAsset = [[AVURLAsset alloc] initWithURL:videoUrl options:nil];
    //创建AVMutableComposition对象来添加视频音频资源的AVMutableCompositionTrack
    AVMutableComposition* mixComposition = [AVMutableComposition composition];
    
    //视频采集compositionVideoTrack
   AVVideoComposition * videoComposition =  [self addVideoCompositionTrack:mixComposition timeRange:CMTimeRangeMake(kCMTimeZero, videoAsset.duration) assert:videoAsset];
    
    //AVAssetExportSession用于合并文件，导出合并后文件，presetName文件的输出类型
    NSString *outPutPath = [kCachesVideoStorageEdit stringByAppendingPathComponent:kDubVideoPath];
    [self exportVideoSession:mixComposition outPath:outPutPath videoComposition:videoComposition completion:completionHandle];
}
//MARK: 合并配音文件
+ (void)addBackgroundMiusicWithVideoUrlStr:(NSURL *)videoUrl audioUrl:(NSURL *)audioUrl completion:(void(^)(NSURL * outPutUrl,NSError * error))completionHandle {
    AVURLAsset* audioAsset = [[AVURLAsset alloc] initWithURL:audioUrl options:nil];
    AVURLAsset* videoAsset = [[AVURLAsset alloc] initWithURL:videoUrl options:nil];
    //创建AVMutableComposition对象来添加视频音频资源的AVMutableCompositionTrack
    AVMutableComposition* mixComposition = [AVMutableComposition composition];
    //截取长度videoDuration
    CMTimeRange videoTimeRange = CMTimeRangeMake(kCMTimeZero, videoAsset.duration);
    //视频采集compositionVideoTrack
   AVVideoComposition * videoComposition = [self addVideoCompositionTrack:mixComposition timeRange:videoTimeRange assert:videoAsset];

    //外部音频采集，最后合成到原视频，与原视频的音频不冲突
    //声音长度截取范围==视频长度
    CMTimeRange audioTimeRange = videoTimeRange;
    if (audioUrl) {
        [self addAudioCompositionTrack:mixComposition timeRange:audioTimeRange assert:audioAsset];
    }
    NSString *outPutPath = [kCachesVideoStorageEdit stringByAppendingPathComponent:kMergeVideoPath];
    //导出视频
    [self exportVideoSession:mixComposition outPath:outPutPath videoComposition:videoComposition completion:completionHandle];
}
//MARK: 添加视频 轨道
/**
 添加视频 轨道

 @param mixComposition 合成器
 @param asset 源
 @param timeRange  视频返回
 @return 视频合成方案
 */

+ (AVVideoComposition *)addVideoCompositionTrack:(AVMutableComposition *)mixComposition timeRange:(CMTimeRange)timeRange assert:(AVURLAsset *)asset{
    //音频采集compositionCommentaryTrack
    //TimeRange截取的范围长度
    //ofTrack来源
    //atTime插放在视频的时间位置
    NSError * error = nil;
    //音频混合轨道
    AVMutableCompositionTrack *compositionTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    //插入视频轨道
    //    1.
    [compositionTrack insertTimeRange:timeRange ofTrack:([asset tracksWithMediaType:AVMediaTypeVideo].count > 0) ? [asset tracksWithMediaType:AVMediaTypeVideo].firstObject : nil atTime:kCMTimeZero error:&error];
    //下面3行代码用于保证后面输出的视频方向跟原视频方向一致
    AVAssetTrack *assetVideoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo]firstObject];
    [compositionTrack setPreferredTransform:assetVideoTrack.preferredTransform];
    NSLog(@"帧率：%f，比特率：%f", assetVideoTrack.nominalFrameRate,assetVideoTrack.estimatedDataRate);
    //    2.
    AVMutableVideoCompositionLayerInstruction *videolayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:compositionTrack];
    [videolayerInstruction setOpacity:0.0 atTime:compositionTrack.asset.duration];
    //    3.
    AVMutableVideoCompositionInstruction *videoCompositionInstrution = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    videoCompositionInstrution.timeRange = CMTimeRangeMake(kCMTimeZero, compositionTrack.asset.duration);
    videoCompositionInstrution.layerInstructions = @[videolayerInstruction];
    //    4.
    AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoComposition];
    videoComposition.renderSize =  CGSizeMake(compositionTrack.naturalSize.width, compositionTrack.naturalSize.height);//视频宽高，必须设置，否则会奔溃
    /*
     电影：24
     PAL（帕尔制，电视广播制式）和SEACM（）：25
     NTSC（美国电视标准委员会）：29.97
     Web/CD-ROM：15
     其他视频类型，非丢帧视频，E-D动画 30
     */
    //    videoComposition.frameDuration = CMTimeMake(1, 43);//必须设置，否则会奔溃，一般30就够了
    videoComposition.frameDuration = CMTimeMake(1, 30);//必须设置，否则会奔溃，一般30就够了
    //    videoComposition.renderScale
    videoComposition.instructions = [NSArray arrayWithObject:videoCompositionInstrution];
    NSLog(@"error---%@",error);
    
    return videoComposition;
}
//MARK: 添加声音 轨道
/**
 添加声音 轨道，
 
 @param mixComposition 合成器
 @param asset 源
 @param timeRange  视频返回
 */
+ (void)addAudioCompositionTrack:(AVMutableComposition *)mixComposition timeRange:(CMTimeRange)timeRange assert:(AVURLAsset *)asset{
    //音频采集compositionCommentaryTrack
    //TimeRange截取的范围长度
    //ofTrack来源
    //atTime插放在视频的时间位置
    NSError * error = nil;
    //这里采用信号量加锁，是声音转换完成之后继续进行合成视频
    dispatch_semaphore_t t = dispatch_semaphore_create(0);
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self changeAudioTypeToCAFAsset:asset Complete:^(AVURLAsset *newAudioAsset, NSError *error) {
            AVAssetTrack *audioAssetTrack = [[newAudioAsset tracksWithMediaType:AVMediaTypeAudio] firstObject];
            AVMutableCompositionTrack * audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
            // 加入合成轨道之中
            [audioTrack insertTimeRange:timeRange ofTrack:audioAssetTrack atTime:CMTimeMakeWithSeconds(0, asset.duration.timescale) error:nil];
            dispatch_semaphore_signal(t);
        }];
    });
    dispatch_semaphore_wait(t, DISPATCH_TIME_FOREVER);
    NSLog(@"error---%@",error);
}
//MARK: 转换声音频道
/**
 声音轨道转换成caf
 这里值得注意的是：因为iOS对MP4视频要求高，如果需要合成MP4视频声音轨道必须使用aac格式的，所以这里视频采用mov格式，声音频道使用caf格式的，内部包含将视频源中间的声道转换成caf格式的

 @param asset 源
 @param handle (新输出的声音路径，错误信息)
 */
+ (void)changeAudioTypeToCAFAsset:(AVURLAsset *)asset Complete:(void(^)(AVURLAsset * newAudioAsset,NSError * error))handle {
    AVMutableComposition *composition = [AVMutableComposition composition];
    
    AVAssetTrack *audioAssetTrack = [[asset tracksWithMediaType:AVMediaTypeAudio] firstObject];
    
    AVMutableCompositionTrack * audioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    // 加入合成轨道之中
    CMTimeRange audioTimeRange = CMTimeRangeMake(kCMTimeZero, asset.duration);
    //插入音频
    [audioTrack insertTimeRange:audioTimeRange ofTrack:audioAssetTrack atTime:CMTimeMakeWithSeconds(0, asset.duration.timescale) error:nil];
    
    //合成器
    AVAssetExportSession *exportSesstion = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetPassthrough];
    
    //输出路径
    NSString * path = [kCachesVideoStorageEdit stringByAppendingPathComponent:kMergeAudioPath];
    if ([[NSFileManager defaultManager]fileExistsAtPath:path]) {
        [[NSFileManager defaultManager]removeItemAtPath:path error:nil];
    }
    exportSesstion.outputURL = [NSURL fileURLWithPath:path];
    exportSesstion.outputFileType = AVFileTypeCoreAudioFormat;
    exportSesstion.shouldOptimizeForNetworkUse = YES;
    [exportSesstion exportAsynchronouslyWithCompletionHandler:^{
        AVAssetExportSessionStatus status = exportSesstion.status;
        if (status == AVAssetExportSessionStatusCompleted) {
            NSLog(@"声音导出成功");
            AVURLAsset * newAudioAsset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:path] options:nil];
            if (handle) {
                handle(newAudioAsset,nil);
            }
        }else{
            NSLog(@"声音导出失败%@",exportSesstion.error);
            if (handle) {
                handle(nil,exportSesstion.error);
            }
        }
    }];
}
//MARK: 导出合成视频
/**
 导出合成视频

 @param mixComposition 合成器
 @param outPutPath 输出路径
 @param videoComposition 设置导出视频的处理方案
 @param completionHandle 完成
 */
+ (void)exportVideoSession:(AVMutableComposition *)mixComposition outPath:(NSString *)outPutPath videoComposition:(AVVideoComposition *)videoComposition completion:(void(^)(NSURL * outPutUrl,NSError * error))completionHandle {
    
    //AVAssetExportSession用于合并文件，导出合并后文件，presetName文件的输出类型
    AVAssetExportSession *assetExportSession = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetPassthrough];
    
    //混合后的视频输出路径
    NSURL *outPutUrl = [NSURL fileURLWithPath:outPutPath];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:outPutPath]){
        [[NSFileManager defaultManager] removeItemAtPath:outPutPath error:nil];
    }
    //输出视频格式 AVFileTypeMPEG4 AVFileTypeQuickTimeMovie...
    assetExportSession.outputFileType = AVFileTypeQuickTimeMovie;
    //    NSArray *fileTypes = assetExportSession.
    assetExportSession.outputURL = outPutUrl;
    //输出文件是否网络优化
    assetExportSession.shouldOptimizeForNetworkUse = YES;
    //设置导出视频的处理方案
    if (videoComposition) {
        assetExportSession.videoComposition = videoComposition;
    }
    
    [assetExportSession exportAsynchronouslyWithCompletionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            if (assetExportSession.status == AVAssetExportSessionStatusCompleted) {
                NSLog(@"转码完成");
            }else {
                NSLog(@"%@",assetExportSession.error);
            }
            completionHandle(outPutUrl,assetExportSession.error);
        });
    }];
}
//MARK: 获取视频时长
/**
 获取视频市场

 @param mediaUrl 路径
 @return value
 */
+ (CGFloat)getMediaDurationWithMediaUrl:(NSURL *)mediaUrl {
    
    AVURLAsset *mediaAsset = [[AVURLAsset alloc] initWithURL:mediaUrl options:nil];
    CMTime duration = mediaAsset.duration;
    
    return duration.value / duration.timescale;
}
+ (NSUInteger)degressFromVideoFileWithURL:(NSURL *)url {
    NSUInteger degress = 0;
    
    AVAsset *asset = [AVAsset assetWithURL:url];
    NSArray *tracks = [asset tracksWithMediaType:AVMediaTypeVideo];
    if([tracks count] > 0) {
        AVAssetTrack *videoTrack = [tracks objectAtIndex:0];
        CGAffineTransform t = videoTrack.preferredTransform;
        
        if(t.a == 0 && t.b == 1.0 && t.c == -1.0 && t.d == 0){
            // Portrait
            degress = 90;
        }else if(t.a == 0 && t.b == -1.0 && t.c == 1.0 && t.d == 0){
            // PortraitUpsideDown
            degress = 270;
        }else if(t.a == 1.0 && t.b == 0 && t.c == 0 && t.d == 1.0){
            // LandscapeRight
            degress = 0;
        }else if(t.a == -1.0 && t.b == 0 && t.c == 0 && t.d == -1.0){
            // LandscapeLeft
            degress = 180;
        }
    }
    return degress;
}
 //MARK: 获取视频缩略图
/**
 获取视频缩略图

 @param url 视频路径
 @return 图片
 */
+ (CGImageRef)thumbnailImageRequestWithURL:(NSURL *)url
{
    //根据url创建AVURLAsset
    AVURLAsset *urlAsset=[AVURLAsset assetWithURL:url];
    
    //根据AVURLAsset创建AVAssetImageGenerator
    AVAssetImageGenerator *imageGenerator=[AVAssetImageGenerator assetImageGeneratorWithAsset:urlAsset];
    imageGenerator.appliesPreferredTrackTransform = YES;
    /*截图
     * requestTime:缩略图创建时间
     * actualTime:缩略图实际生成的时间
     */
    NSError *error=nil;
    CMTime time = CMTimeMake(0, 10);
    //    CMTime time=CMTimeMakeWithSeconds(0, 10);//CMTime是表示视频时间信息的结构体，第一个参数表示是视频第几秒，第二个参数表示每秒帧数.(如果要获取的某一秒的第几帧可以使用CMTimeMake方法)
    CMTime actualTime;
    CGImageRef cgImage= [imageGenerator copyCGImageAtTime:time actualTime:&actualTime error:&error];
    if(error){
        NSLog(@"截取视频缩略图时发生错误，错误信息：%@",error.localizedDescription);
    }
    CMTimeShow(actualTime);
    return cgImage;
}
//MARK: 转换视频格式，导出视频
/**
 转换视频格式，导出视频
 
 @param inputURL 输入源
 @param outputURL 输出源
 @param handler 回调
 */
+ (void)exportSessionVideoWithInputURL:(NSURL*)inputURL completion:(void(^)(NSURL * outPutUrl,NSError * error))completionHandle{
    if (!inputURL.path || [inputURL.path isEqualToString:@""] || inputURL.path.length == NSNotFound) {
        return;
    }
    //AVURLAsset此类主要用于获取媒体信息，包括视频、声音等
    AVURLAsset* videoAsset = [[AVURLAsset alloc] initWithURL:inputURL options:nil];
    NSArray *tracks = videoAsset.tracks;
    NSLog(@"所有轨道:%@\n",tracks);//打印出所有的资源轨道
    //创建AVMutableComposition对象来添加视频音频资源的AVMutableCompositionTrack
    AVMutableComposition* mixComposition = [AVMutableComposition composition];
    //视频采集compositionVideoTrack 添加视频轨道
    AVVideoComposition * videoComposition = [self addVideoCompositionTrack:mixComposition timeRange:CMTimeRangeMake(kCMTimeZero, videoAsset.duration) assert:videoAsset];
    //视频声音采集(也可不执行这段代码不采集视频音轨，合并后的视频文件将没有视频原来的声音)
    [self addAudioCompositionTrack:mixComposition timeRange:CMTimeRangeMake(kCMTimeZero, videoAsset.duration) assert:videoAsset];
    //AVAssetExportSession用于合并文件，导出合并后文件，presetName文件的输出类型
    NSString *outPutPath = [kCachesVideoStorageEdit stringByAppendingPathComponent:@"convertVideo.mov"];
    [self exportVideoSession:mixComposition outPath:outPutPath videoComposition:videoComposition completion:completionHandle];
    
    
}

//MARK: 相册读取之后照片路径，内部会将相册内部的视频缓存至沙盒路径
/**
 相册读取之后照片路径，内部会将相册内部的视频缓存至沙盒路径
 
 @param info imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
 @param result 缓存路径
 */
+ (void)getVideoLocalPath:(NSDictionary<NSString *,id> *)info result:(void(^)(NSURL * videoURL))result {
    NSURL *videoURL = [info objectForKey:UIImagePickerControllerMediaURL];      // video path
    if (videoURL) {
        //处于沙盒下的 直接返回就可以了
        if (result) {
            result(videoURL);
        }
    } else {
        //先判断权限
        [self checkVideoPermissionCompletionHandler:^(BOOL granted) {
            if (granted) {
                //相册内的视频，需要先缓存到沙盒下面才能使用
                NSURL *imageURL = [info valueForKey:UIImagePickerControllerReferenceURL];
                PHFetchResult *fetchResult = [PHAsset fetchAssetsWithALAssetURLs:@[imageURL] options:nil];
                PHAsset *asset = fetchResult.firstObject;
                NSArray *assetResources = [PHAssetResource assetResourcesForAsset:asset];
                PHAssetResource *resource;
                for (PHAssetResource *assetRes in assetResources) {
                    if (assetRes.type == PHAssetResourceTypePairedVideo ||
                        assetRes.type == PHAssetResourceTypeVideo) {
                        resource = assetRes;
                    }
                }
                if (asset.mediaType == PHAssetMediaTypeVideo || asset.mediaSubtypes == PHAssetMediaSubtypePhotoLive) {
                    PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
                    options.version = PHImageRequestOptionsVersionCurrent;
                    options.deliveryMode = PHVideoRequestOptionsDeliveryModeAutomatic;
                    //#warning***视频路径一定要放置cache路径下面，不可以放在Temp路径下，否则导出的时候会有问题。****
                    NSString * PATH_MOVIE_FILE = [kCachesVideoStorageEdit stringByAppendingPathComponent:kTempAssetVideo];
                    if ([[NSFileManager defaultManager]fileExistsAtPath:PATH_MOVIE_FILE]) {
                        [[NSFileManager defaultManager]removeItemAtPath:PATH_MOVIE_FILE error:nil];
                    }
                    [[PHAssetResourceManager defaultManager] writeDataForAssetResource:resource
                                                                                toFile:[NSURL fileURLWithPath:PATH_MOVIE_FILE]
                                                                               options:nil
                                                                     completionHandler:^(NSError * _Nullable error) {
                                                                         if (error) {
                                                                             [JWHudLoadView alertMessage:error.domain];
                                                                         } else {
                                                                             NSLog(@"=====filePath:%@",PATH_MOVIE_FILE);
                                                                             if (result) {
                                                                                 result([NSURL fileURLWithPath:PATH_MOVIE_FILE]);
                                                                             }
                                                                         }
                                                                     }];
                } else {
                    [JWHudLoadView alertMessage:@"暂不支持该视频，请选择其他视频!"];
                }
            }else {
                 [JWHudLoadView alertMessage:@"需要您同意相册权限"];
            }
        }];
    }
}


//MARK: 清楚剪辑视频缓存
/**
 清楚剪辑视频缓存
 */
+ (void)clearCutVideoCache {
    NSLog(@"-------清除上传视频资源");
    NSString *outPutPath = [kCachesVideoStorageEdit stringByAppendingPathComponent:kCutVideoPath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:outPutPath]) {
        [[NSFileManager defaultManager] removeItemAtPath:outPutPath error:nil];
    }
    outPutPath = [kCachesVideoStorageEdit stringByAppendingPathComponent:kDubVideoPath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:outPutPath]) {
        [[NSFileManager defaultManager] removeItemAtPath:outPutPath error:nil];
    }
    outPutPath = [kCachesVideoStorageEdit stringByAppendingPathComponent:kMergeVideoPath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:outPutPath]) {
        [[NSFileManager defaultManager] removeItemAtPath:outPutPath error:nil];
    }
    
    outPutPath = [kCachesVideoStorageEdit stringByAppendingPathComponent:kMergeAudioPath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:outPutPath]) {
        [[NSFileManager defaultManager] removeItemAtPath:outPutPath error:nil];
    }
}


@end
