//
//  JWVideoEditVC.m
//  JWVideoEdit
//
//  Created by 张竟巍 on 2018/7/31.
//  Copyright © 2018年 ACAA. All rights reserved.
//

#import "JWVideoEditVC.h"
#import "JWHudLoadView.h"
#import "JWVideoThumbView.h"
#import <AVFoundation/AVFoundation.h>
#import "JWVideoEditManage.h"
#import "UIViewController+JWVideoEditAlert.h"

@interface JWVideoEditVC ()

@property (strong, nonatomic)AVPlayer * player;//播放器
@property (strong, nonatomic)AVPlayerLayer *playerLayer;//播放界面（layer）
@property (strong, nonatomic)AVPlayerItem *item;//播放单元
@property (nonatomic, strong) JWHudLoadView * hudView; //提醒load

@property(atomic,strong) NSURL *url; //播放的url

@property (weak, nonatomic) IBOutlet JWVideoThumbView *videoPieces;//缩略图
@property (nonatomic,assign)BOOL seeking; //标识是否在滑动
@property (nonatomic,assign)CGFloat totalSeconds;
@property (nonatomic,assign)CGFloat lastStartSeconds;
@property (nonatomic,assign)CGFloat lastEndSeconds;

@property (weak, nonatomic) IBOutlet UILabel *startTimeLabel; //开始时间
@property (weak, nonatomic) IBOutlet UILabel *endTimeLabel;  //结束时间

@property (nonatomic, copy) CutVideoBlock cutBlock;
@property (nonatomic, strong) id timeObserver;
@end

@implementation JWVideoEditVC

+ (void)presentFromViewController:(UIViewController *)viewController url:(NSURL *)url completion:(CutVideoBlock)cutBlock {
    [viewController presentViewController:[[JWVideoEditVC alloc] initWithURL:url completion:cutBlock] animated:YES completion:nil];
}
- (id)initWithURL:(NSURL *)url completion:(CutVideoBlock)cutBlock {
    if (self = [super init]) {
        self.url = url;
        self.cutBlock = cutBlock;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    //播放器
    [self initSGPlayer];
    //缩略图
    [self initThumbBlock];
    //app退到后台
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appDidEnterBackground)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
    
}
//MARK: 取消完成
- (IBAction)cancelClick:(UIButton *)sender {
    [self dismiss];
}
- (IBAction)doneClick:(UIButton *)sender {
    if (self.lastEndSeconds - self.lastStartSeconds < 1) {
        [JWHudLoadView alertMessage:@"录制太短，请重试选择视频"];
        return;
    }
    [self.player pause];
    [self.hudView hudShow:self.view msg:@"正在裁剪..."];
    __block __weak typeof(self)weakSelf = self;
    TimeRange timeRange = {self.lastStartSeconds,self.lastEndSeconds-self.lastStartSeconds};
    
    [JWVideoEditManage captureVideoWithVideoUrl:_url timeRange:timeRange completion:^(NSURL *outPutUrl, NSError * error) {
        if (!error) {
            NSLog(@"已经完成");
            [weakSelf.hudView hudclose];
            //将视频保存在本地
            [weakSelf saveVideo:outPutUrl];
            
            if (weakSelf.cutBlock) {
                weakSelf.cutBlock(outPutUrl);
            }
        }else {
            [JWHudLoadView alertMessage:@"剪切视频出错，请退出重试"];
        }
        [weakSelf dismiss];
    }];
}
- (void)initThumbBlock {
    __weak __block typeof(self)weakSelf = self;
    //左边滑块
    [_videoPieces setBlockSeekOffLeft:^(CGFloat offX) {
        weakSelf.seeking = true;
        [weakSelf.player pause];
        weakSelf.lastStartSeconds = weakSelf.totalSeconds * offX / CGRectGetWidth(weakSelf.videoPieces.bounds);
        [weakSelf.player seekToTime:CMTimeMakeWithSeconds(weakSelf.lastStartSeconds, NSEC_PER_SEC)];
        weakSelf.startTimeLabel.text = [weakSelf timeStringFromSeconds:weakSelf.lastStartSeconds];
    }];
    //右边边滑块
    [_videoPieces setBlockSeekOffRight:^(CGFloat offX) {
        weakSelf.seeking = true;
        [weakSelf.player pause];
        weakSelf.lastEndSeconds = weakSelf.totalSeconds*offX / CGRectGetWidth(weakSelf.videoPieces.bounds);
        [weakSelf.player seekToTime:CMTimeMakeWithSeconds(weakSelf.lastEndSeconds, NSEC_PER_SEC)];
        weakSelf.endTimeLabel.text = [weakSelf timeStringFromSeconds:weakSelf.lastEndSeconds];
    }];
    //滑动结束
    [_videoPieces setBlockMoveEnd:^{
        NSLog(@"滑动结束");
        if (weakSelf.seeking) {
            weakSelf.seeking = false;
            [weakSelf.player seekToTime:CMTimeMakeWithSeconds(weakSelf.lastStartSeconds, NSEC_PER_SEC)];
            [weakSelf.player play];
        }
    }];
    //添加缩略图
    CGFloat widthIV = (CGRectGetWidth(_videoPieces.frame))/10.0;
    CGFloat heightIV = CGRectGetHeight(_videoPieces.frame);
    [self getVideoThumbnail:_url count:10 splitCompleteBlock:^(BOOL success, NSMutableArray *splitimgs) {
        for (int i = 0; i<splitimgs.count; i++) {
            UIImageView *iv = [[UIImageView alloc] initWithFrame:CGRectMake(i*widthIV, 3, widthIV, heightIV-6)];
            iv.contentMode = UIViewContentModeScaleToFill;
            iv.image = splitimgs[i];
            [weakSelf.videoPieces insertSubview:iv atIndex:1];
        }
    }];
}
//MARK: 初始化播放器
- (void)initSGPlayer {
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    //构建播放单元
    self.item = [AVPlayerItem playerItemWithURL:self.url];
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
//kvo 监听播放开始
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    AVPlayerItem *item = (AVPlayerItem *)object;
    if ([keyPath isEqualToString:@"status"]) {
        if ([item status] == AVPlayerStatusReadyToPlay) {
            //开始播放
            if (self.totalSeconds <= 0) {
                //首次进入赋值就行
                self.endTimeLabel.text = [self timeStringFromSeconds:CMTimeGetSeconds(item.asset.duration)];
                self.lastEndSeconds = CMTimeGetSeconds(item.asset.duration);
            }
            self.totalSeconds = CMTimeGetSeconds(item.asset.duration);
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
- (void)monitorPlayingStatusWithItem:(AVPlayerItem *)item
{
    
    __weak typeof(self) tmp = self;
    self.timeObserver = [self.playerLayer.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        
        NSTimeInterval currentTime = CMTimeGetSeconds(time);
        
        NSLog(@"%f",currentTime);
        
        if (currentTime > self.lastEndSeconds) {
            //跳转至 滑块处播放
            [tmp.player seekToTime:CMTimeMakeWithSeconds(tmp.lastStartSeconds, NSEC_PER_SEC)];
            [tmp.player play];
        }
        
    }];
}
- (void)playbackFinished:(NSNotification *)notifi {
    NSLog(@"播放结束");
    //跳转至 滑块处播放
    [self.player seekToTime:CMTimeMakeWithSeconds(self.lastStartSeconds, NSEC_PER_SEC)];
    [self.player play];
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
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication]setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[UIApplication sharedApplication]setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
}
//MARK: 获取缩略图
- (NSArray *)getVideoThumbnail:(NSURL *)path count:(NSInteger)count splitCompleteBlock:(void(^)(BOOL success, NSMutableArray *splitimgs))splitCompleteBlock {
    AVAsset *asset = [AVAsset assetWithURL:path];
    NSMutableArray *arrayImages = [NSMutableArray array];
    [asset loadValuesAsynchronouslyForKeys:@[@"duration"] completionHandler:^{
        AVAssetImageGenerator *generator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
        //        generator.maximumSize = CGSizeMake(480,136);//如果是CGSizeMake(480,136)，则获取到的图片是{240, 136}。与实际大小成比例
        generator.appliesPreferredTrackTransform = YES;//这个属性保证我们获取的图片的方向是正确的。比如有的视频需要旋转手机方向才是视频的正确方向。
        /**因为有误差，所以需要设置以下两个属性。如果不设置误差有点大，设置了之后相差非常非常的小**/
        generator.requestedTimeToleranceAfter = kCMTimeZero;
        generator.requestedTimeToleranceBefore = kCMTimeZero;
        Float64 seconds = CMTimeGetSeconds(asset.duration);
        NSMutableArray *array = [NSMutableArray array];
        for (int i = 0; i<count; i++) {
            CMTime time = CMTimeMakeWithSeconds(i*(seconds/10.0),1);//想要获取图片的时间位置
            [array addObject:[NSValue valueWithCMTime:time]];
        }
        __block int i = 0;
        [generator generateCGImagesAsynchronouslyForTimes:array completionHandler:^(CMTime requestedTime, CGImageRef  _Nullable imageRef, CMTime actualTime, AVAssetImageGeneratorResult result, NSError * _Nullable error) {
            i++;
            if (result==AVAssetImageGeneratorSucceeded) {
                UIImage *image = [UIImage imageWithCGImage:imageRef];
                [arrayImages addObject:image];
            }else{
                NSLog(@"获取图片失败！！！");
            }
            if (i==count) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    splitCompleteBlock(YES,arrayImages);
                });
            }
        }];
    }];
    return arrayImages;
}
- (void)dismiss {
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)dealloc {
    if (self.player) {
        [self.item removeObserver:self forKeyPath:@"status"];
        [[NSNotificationCenter defaultCenter]removeObserver:self];
        [self.playerLayer.player removeTimeObserver:self.timeObserver];
        self.player = nil;
    }
}

//videoPath为视频下载到本地之后的本地路径
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

- (JWHudLoadView *)hudView {
    if (!_hudView) {
        _hudView = [[JWHudLoadView alloc]init];
    }
    return _hudView;
}

@end
