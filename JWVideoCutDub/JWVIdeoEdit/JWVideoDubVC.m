//
//  JWVideoDubVC.m
//  JWVideoEdit
//
//  Created by 张竟巍 on 2018/8/1.
//  Copyright © 2018年 ACAA. All rights reserved.
//

#import "JWVideoDubVC.h"
#import <AVFoundation/AVFoundation.h>
#import "JWHudLoadView.h"
#import "UIViewController+JWVideoEditAlert.h"
#import "JWVideoEditManage.h"
#import "JWAudioEditManage.h"
#import "JWAudioWaverView.h"


@interface JWVideoDubVC ()
@property (weak, nonatomic) IBOutlet UIView *topView; //顶部view
@property (weak, nonatomic) IBOutlet UIView *bottomView;  //底部view
@property (weak, nonatomic) IBOutlet JWAudioWaverView *audioWaveView; //波纹

@property (weak, nonatomic) IBOutlet UILabel *timeLabel; //时间

@property (strong, nonatomic)AVPlayer * player;//播放器
@property (strong, nonatomic)AVPlayerLayer *playerLayer;//播放界面（layer）
@property (strong, nonatomic)AVPlayerItem *item;//播放单元
@property (nonatomic, strong) JWHudLoadView * hudView; //提醒load

@property(atomic,strong) NSURL *url; //播放的url
@property (nonatomic, strong) NSURL * outPutUrl; //去除声道的url

@property (nonatomic, copy) NSString * totalTime;

@property (nonatomic, assign) BOOL              isShow;  //是否显示控制器

@property (nonatomic, copy) DubVideoBlock dubBlock;
@property (nonatomic, strong) id timeObserver;

@end

@implementation JWVideoDubVC

+ (void)presentFromViewController:(UIViewController *)viewController url:(NSURL *)url completion:(DubVideoBlock)dubBlock{
    [viewController presentViewController:[[JWVideoDubVC alloc] initWithURL:url completion:dubBlock] animated:YES completion:nil];
}
- (id)initWithURL:(NSURL *)url completion:(DubVideoBlock)dubBlock {
    if (self = [super init]) {
        self.url = url;
        self.dubBlock = dubBlock;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.topView.backgroundColor = self.bottomView.backgroundColor = [[UIColor blackColor]colorWithAlphaComponent:0.5];
    [self deleteAudioAction];
    //app退到后台
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appDidEnterBackground)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
}
//MARK: 合并视频
- (void)mergeDubVideo {
    NSURL * outPutUrl = self.outPutUrl;
    NSURL * videoUrl = [NSURL fileURLWithPath:[[JWAudioEditManage shareInstance]getAudioPath]];
    if (!outPutUrl || !videoUrl) {
        return;
    }
    [self.hudView hudShow:self.view msg:@"正在合成..."];
    __block __weak typeof(self)weakSelf = self;
    [JWVideoEditManage addBackgroundMiusicWithVideoUrlStr:outPutUrl audioUrl:videoUrl completion:^(NSURL *outPutUrl, NSError * error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!error) {
                NSLog(@"已经完成");
                [weakSelf.hudView hudclose];
                [weakSelf saveVideo:outPutUrl];
                
                if (weakSelf.dubBlock) {
                    weakSelf.dubBlock(outPutUrl);
                }
            }else {
                [JWHudLoadView alertMessage:@"配音视频出错，请退出重试"];
            }
            [weakSelf dismiss];
        });
    }];
}

//MARK: 初始化播放器
- (void)initSGPlayer:(NSURL *)url {
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    //构建播放单元
    self.item = [AVPlayerItem playerItemWithURL:url];
    //构建播放器对象
    self.player = [AVPlayer playerWithPlayerItem:self.item];
    //构建播放器的layer
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    self.playerLayer.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - 160);
    [self.view.layer addSublayer:self.playerLayer];
    //通过KVO来观察status属性的变化，来获得播放之前的错误信息
    [self.item addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    //添加播放结束监听
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackFinished:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.item];
    [self.player play];
    
}
//MARK: 删除声道
- (void)deleteAudioAction {
    __block __weak typeof(self)weakSelf = self;
    //去除视频声道
    [self.hudView hudShow:self.view msg:@"正在删除声音.."];
    [JWVideoEditManage deleteVideoAudio:_url completion:^(NSURL *outPutUrl, NSError *error) {
        //提醒
        [weakSelf.hudView hudclose];
        if (!error) {
            [weakSelf showMyAlertWithMessage:@"您已经准备好了么？(请选择安静的地方进行配音)" hanler:^{
                //检查录音权限
                [[JWAudioEditManage shareInstance]checkPermissionCompletionHandler:^(BOOL granted) {
                    if (granted) {
                        weakSelf.audioWaveView.waverLevelCallback = ^(JWAudioWaverView *waver) {
                            [[JWAudioEditManage shareInstance].recorder updateMeters];
                            CGFloat normalizedValue = pow (10, [[JWAudioEditManage shareInstance].recorder averagePowerForChannel:0] / 40);
                            waver.level = normalizedValue;
                        };
                        //播放源
                        weakSelf.outPutUrl = outPutUrl;
                        [weakSelf initSGPlayer:outPutUrl];
                    }else {
                        [weakSelf showMyAlertWithMessage:@"请在\n设置-隐私-相机\n选项中，允许访问你的录音。" hanler:nil cancel:nil];
                    }
                }];
            } cancel:^{
                [weakSelf dismiss];
            }];
        }else {
            [JWHudLoadView alertMessage:@"合成视频出错，请退出重试"];
        }
    }];
}
//kvo 监听播放开始
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    AVPlayerItem *item = (AVPlayerItem *)object;
    if ([keyPath isEqualToString:@"status"]) {
        if ([item status] == AVPlayerStatusReadyToPlay) {
            //开始播放
            self.totalTime = [self timeStringFromSeconds:CMTimeGetSeconds(item.asset.duration)];
            //开始录音
            [[JWAudioEditManage shareInstance]startAudioRecorder];
            [self monitorPlayingStatusWithItem:item];
        }
    }else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}
/**
 *  监听播放状态
 *
 */
- (void)monitorPlayingStatusWithItem:(AVPlayerItem *)item {
    __weak typeof(self) tmp = self;
    self.timeObserver = [self.playerLayer.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        NSTimeInterval currentTime = CMTimeGetSeconds(time);
        NSLog(@"%f",currentTime);
        tmp.timeLabel.text = [NSString stringWithFormat:@"%@/%@",[tmp timeStringFromSeconds:currentTime],[tmp.totalTime isEqualToString:@""]? @"00:00":tmp.totalTime];
    }];
}
- (void)playbackFinished:(NSNotification *)notifi {
    NSLog(@"播放结束");
    //播放结束播放
    //合成视频
    [[JWAudioEditManage shareInstance]stopAudioRecorder];
    [self.player pause];
    [self mergeDubVideo];
}


- (NSString *)timeStringFromSeconds:(CGFloat)f_seconds
{
    int seconds = floorf(f_seconds);
    int second = seconds % 60;
    int minutes = (seconds / 60) % 60;
    return [NSString stringWithFormat:@"%02d:%02d", minutes, second];
}
- (void)appDidEnterBackground
{
    [self.player pause];
    [[JWAudioEditManage shareInstance]pauseAudioRecorder];
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication]setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[UIApplication sharedApplication]setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
}
//MARK: 功能按钮
- (IBAction)backClick:(UIButton *)sender {
    [self dismiss];
    
}
- (void)dismiss {
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (IBAction)pauseOrPlayClick:(UIButton *)sender {
    sender.selected = !sender.selected;
    if (sender.isSelected) {
        [self.player pause];
        //暂停录音
        [[JWAudioEditManage shareInstance]pauseAudioRecorder];
    }else {
        [self.player play];
        //暂停录音
        [[JWAudioEditManage shareInstance]startAudioRecorder];
    }
}

- (JWHudLoadView *)hudView {
    if (!_hudView) {
        _hudView = [[JWHudLoadView alloc]init];
    }
    return _hudView;
}
- (void)showContrloView {
    _isShow = YES;
    self.topView.hidden = self.bottomView.hidden = NO;
//    [self performSelector:@selector(hiddenControlView) withObject:nil afterDelay:5];
}
- (void)hiddenControlView {
    _isShow = NO;
    self.topView.hidden = self.bottomView.hidden = YES;
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hiddenControlView) object:nil];
}
//MARK: videoPath为视频下载到本地之后的本地路径
- (void)saveVideo:(NSURL *)videoPath{
    NSString *urllStr = videoPath.path;
    if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(urllStr)) {
        //保存相册核心代码
        UISaveVideoAtPathToSavedPhotosAlbum(urllStr, self, @selector(video:didFinishSavingWithError:contextInfo:), nil);
    }
    
}
//保存视频完成之后的回调
- (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    if (error) {
        NSLog(@"保存视频失败%@", error.localizedDescription);
    }
    else {
        NSLog(@"保存视频成功");
    }
}

-(void)dealloc {
    if (self.player) {
        [self.item removeObserver:self forKeyPath:@"status"];
        [[NSNotificationCenter defaultCenter]removeObserver:self];
        [self.playerLayer.player removeTimeObserver:self.timeObserver];
        self.player = nil;
    }
}

@end
