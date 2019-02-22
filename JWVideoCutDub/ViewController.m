//
//  ViewController.m
//  JWVideoCutDub
//
//  Created by 张竟巍 on 2019/2/21.
//  Copyright © 2019 张竟巍. All rights reserved.
//

#import "ViewController.h"
#import "JWVideoEditVC.h"
#import "JWVideoDubVC.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "JWVideoEditManage.h"
#import "JWHudLoadView.h"
#import "UIViewController+JWVideoEditAlert.h"

typedef NS_ENUM(NSInteger, SelectVideoType) {
    SelectVideoCutType, //剪切
    SelectVideoDubType //配音
};

@interface ViewController () <UINavigationControllerDelegate,UIImagePickerControllerDelegate>
@property (nonatomic, strong) UIImagePickerController   *videoPicker;
@property (nonatomic, strong) UIImagePickerController   *photoVideoPicker;
@property (nonatomic, strong) JWHudLoadView * hudView;

@property (nonatomic, assign) SelectVideoType videoType;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}
//MARK: 剪切视频
- (IBAction)cutVideoAction:(id)sender {
    _videoType = SelectVideoCutType;
    [self selectedVideo];
}
//MARK: 视频重新配音
- (IBAction)dubVideoAction:(id)sender {
    _videoType = SelectVideoDubType;
    [self selectedVideo];
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    // 获取视频的url,当选中某个文件时该文件会被读取到沙盒的temp路径下
    [self dismissViewControllerAnimated:YES completion:nil]; 
    __weak typeof(self)weakSelef = self;
    [JWVideoEditManage getVideoLocalPath:info result:^(NSURL * videoURL) {
        //对视频进行处理
        [weakSelef.hudView hudShow:weakSelef.view msg:@"处理视频中..."];
        [JWVideoEditManage exportSessionVideoWithInputURL:videoURL completion:^(NSURL *outPutUrl, NSError *error) {
            [weakSelef.hudView hudclose];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (!error) {
                    NSLog(@"succeed======处理视频成功");
                    if (weakSelef.videoType == SelectVideoCutType) {
                        [JWVideoEditVC presentFromViewController:self url:outPutUrl completion:^(NSURL *outputUrl) {
                            NSLog(@"剪切的视频路径:%@",outPutUrl.path);
                            [weakSelef showMyAlertWithMessage:@"视频剪切成功，已保存至相册" hanler:nil cancel:nil];
                        }];
                    }else {
                        [JWVideoDubVC presentFromViewController:self url:outPutUrl completion:^(NSURL *outputUrl) {
                            NSLog(@"配音的视频路径:%@",outPutUrl.path);
                            [weakSelef showMyAlertWithMessage:@"视频重新配音成功，已保存至相册" hanler:nil cancel:nil];
                        }];
                    }
                   
                }else {
                    [JWHudLoadView alertMessage:@"无法处理该视频，请选择其他视频"];
                }
            });
        }];
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)selectedVideo
{
    // 系xr统版本判断
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];

    UIAlertAction *takeVideoAction = [UIAlertAction actionWithTitle:@"拍摄" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self takeVideo];           //普通拍摄上传
    }];
    UIAlertAction *selectFileAction = [UIAlertAction actionWithTitle:@"从相册中选择" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self selectVideoFile];     //选择视频文件上传
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    [alertController addAction:takeVideoAction];
    [alertController addAction:selectFileAction];
    [alertController addAction:cancelAction];
    [self presentViewController:alertController animated:YES completion:nil];
}
#pragma mark -- 选择拍照视频
- (void)takeVideo {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        [self presentViewController:self.videoPicker animated:YES completion:nil];
    }else {
        NSLog(@"无可用摄像头设备");
    }
}
#pragma mark -- 选择系统相册视频
- (void)selectVideoFile {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeSavedPhotosAlbum]) {
        [self presentViewController:self.photoVideoPicker animated:YES completion:nil];
    }else {
        NSLog(@"无可用相册");
    }
}
- (UIImagePickerController *)videoPicker
{
    if (!_videoPicker) {
        _videoPicker = [[UIImagePickerController alloc] init];
        [_videoPicker setSourceType:UIImagePickerControllerSourceTypeCamera];
        [_videoPicker setMediaTypes:@[(NSString *)kUTTypeMovie]];
        [_videoPicker setVideoQuality:UIImagePickerControllerQualityTypeMedium];
        [_videoPicker setCameraCaptureMode:UIImagePickerControllerCameraCaptureModeVideo]; // 摄像头模式
        _videoPicker.delegate = self;
        _videoPicker.editing = YES;     // 允许编辑
        _videoPicker.allowsEditing = YES;
    }
    return _videoPicker;
}
- (UIImagePickerController *)photoVideoPicker {
    if (!_photoVideoPicker) {
        _photoVideoPicker = [[UIImagePickerController alloc] init];
        [_photoVideoPicker setSourceType:UIImagePickerControllerSourceTypeSavedPhotosAlbum];
        [_photoVideoPicker setMediaTypes:@[(NSString *)kUTTypeMovie]];
        _photoVideoPicker.delegate = self;
        _photoVideoPicker.allowsEditing = YES;
    }
    return _photoVideoPicker;
}
- (JWHudLoadView *)hudView {
    if (!_hudView) {
        _hudView = [JWHudLoadView new];
    }
    return _hudView;
}

@end
