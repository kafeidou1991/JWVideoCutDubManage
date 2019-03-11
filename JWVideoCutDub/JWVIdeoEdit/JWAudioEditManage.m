//
//  JWAudioEditManage.m
//  JWVideoEdit
//
//  Created by 张竟巍 on 2018/8/6.
//  Copyright © 2018年 ACAA. All rights reserved.
//

#import "JWAudioEditManage.h"

#define kDubAudioPath @"DubAudioPath.caf"   //剪切的视频配音文件名

//视频配音录音 、压缩裁剪路径
#define kCachesVideoStorageEdit ({\
NSString * path = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"VideoStorageEdit"];\
if (![[NSFileManager defaultManager]fileExistsAtPath:path]) {\
[[NSFileManager defaultManager]createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];\
}\
(path);\
})

@interface JWAudioEditManage () <AVAudioRecorderDelegate>
@property (nonatomic, strong) AVAudioPlayer * audioPlayer;
@end

@implementation JWAudioEditManage

+ (instancetype)shareInstance {
    static JWAudioEditManage * shareInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shareInstance = [[super allocWithZone:NULL]init];
    });
    return shareInstance;
}
+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    return [self shareInstance];
}
//MARK: 检查声音权限
- (void)checkPermissionCompletionHandler:(void (^)(BOOL granted))handler {
    AVAudioSessionRecordPermission permission = [[AVAudioSession sharedInstance] recordPermission];
    if (permission == AVAudioSessionRecordPermissionGranted) {
        [self configRecorder];
        if (handler) {
            handler(YES);
        }
    }else {
        [self resquestUserPermissionCompletionHandler:handler];
    }
}
- (void)resquestUserPermissionCompletionHandler:(void (^)(BOOL granted))handler {
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL granted) {
        if (granted) {
            // 通过验证
            dispatch_async(dispatch_get_main_queue(), ^{
                [self configRecorder];
                if (handler) {
                    handler(YES);
                }
            });
        } else {
            // 未通过验证
            handler(NO);
        }
    }];
}

//MARK: 录音配置
- (void)configRecorder {
    NSURL *fileUrl = [NSURL fileURLWithPath:[self filePathWithName]];
    NSError *error = nil;
    NSDictionary *setting = [self recordSetting];
    self.recorder = [[AVAudioRecorder alloc] initWithURL:fileUrl settings:setting error:&error];
    self.recorder.delegate = self;
    self.recorder.meteringEnabled = YES;
    if ([self.recorder prepareToRecord]) {
    }
    NSLog(@"error>>>>>>>>%@",error);
}
// 录音参数设置
- (NSDictionary *)recordSetting {
    NSMutableDictionary *settings = [[NSMutableDictionary alloc] initWithCapacity:0];
    
    [settings setValue :[NSNumber numberWithInt:kAudioFormatMPEG4AAC] forKey:AVFormatIDKey];//格式
    [settings setValue:[NSNumber numberWithFloat:8000.0] forKey:AVSampleRateKey]; //采样8000次
    [settings setValue:[NSNumber numberWithInt: 1] forKey:AVNumberOfChannelsKey];//声道
    [settings setValue :[NSNumber numberWithInt:8] forKey:AVLinearPCMBitDepthKey];//位深度
    [settings setValue :[NSNumber numberWithBool:NO] forKey:AVLinearPCMIsBigEndianKey];
    [settings setValue :[NSNumber numberWithBool:NO] forKey:AVLinearPCMIsFloatKey];
    //Encoder
    [settings setValue :[NSNumber numberWithInt:12000] forKey:AVEncoderBitRateKey];//采样率
    [settings setValue :[NSNumber numberWithInt:8] forKey:AVEncoderBitDepthHintKey];//位深度
    [settings setValue :[NSNumber numberWithInt:8] forKey:AVEncoderBitRatePerChannelKey];//声道采样率
    [settings setValue :[NSNumber numberWithInt:AVAudioQualityMedium]  forKey:AVEncoderAudioQualityKey];//编码质量
    
    return settings;
}
// Document目录
- (NSString *)filePathWithName{
    NSString *urlStr = [self getAudioPath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:urlStr]){
        [[NSFileManager defaultManager] removeItemAtPath:urlStr error:nil];
    }
    return urlStr;
}
-(NSString *)getAudioPath {
    return [kCachesVideoStorageEdit stringByAppendingPathComponent:kDubAudioPath];
}
//MARK: 开启录音 或者暂停录音
- (void)startAudioRecorder {
    //设置录音模式
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    //设置录音模式
    [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:nil];
    //启动该会话
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    if (_recorder && !_recorder.isRecording) {
        [_recorder record];
        NSLog(@"录音开始");
    }
}
-(void)pauseAudioRecorder {
    if (_recorder && _recorder.isRecording) {
        [_recorder pause];
    }
}
-(void)stopAudioRecorder {
    if (_recorder && _recorder.isRecording) {
        [_recorder stop];
        NSLog(@"录音结束");
        [[AVAudioSession sharedInstance] setActive:NO error:nil];
    }
}
- (void)play {
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    //设置播放模式
    [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
    NSError *error;
    NSURL *audioInputUrl = [NSURL fileURLWithPath:[self getAudioPath]];
    self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:audioInputUrl error:&error];
    NSLog(@"error----%@",error);
    self.audioPlayer.numberOfLoops = 0;
    [self.audioPlayer prepareToPlay];
    [self.audioPlayer play];
}

//MARK: AVAudioDelgegate
- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag {
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    if (flag) {
        // 录音正常结束
    } else {
        // 未正常结束
        if ([_recorder deleteRecording]) {
            // 录音文件删除成功
        } else {
            // 录音文件删除失败
        }
    }
}
-(void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder error:(NSError *)error {
    NSLog(@"<<<<<<<<<<<<<<<%@",error);
//    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
}




@end
