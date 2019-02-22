# JWVideoCutDubManage
描述:iOS 视频剪切 视频配音

### 前言

前段时间公司有个需求是将视频剪切跟重新配音的需求，搜了好多资料发现没有完全满意的。于是自己借助各个大佬们之前的肩膀，自己写了个Demo，希望能够帮到有相同这块需求的同行~，有什么问题或者批评指正的可以QQ我。QQ： 38251725



### 视频剪切

思路：视频剪切功能的实现其实就是使用（AVMutableComposition） 将原视频视频跟音频合并，按照所选时间范围进行重新导出（AVAssetExportSession）。JWVideoEditVC跟JWVideoEditManage这两个类是处理剪切业务的，小伙伴可以自行根据需求修改。

其间碰到的问题：

1. AVAssetExportSession导出失败

   - 错误信息比较模糊。视频导出的路径尽量放在Cache路径下面，再Doc路径下面会出现部分视频导出非常的慢，具体原因我也没研究出来，反正是更换再Cache路径下就正常了。
   - 视频格式，一定要切记视频格式不要弄错。我写的Demo里面的视频格式都是mov格式的。需要MP4格式的童鞋注意一点就是合成的时候声道必须是aaf格式的，否则就导出失败。
   - 输出路径一定要判断是否存在，存在就删除路径。否则也会导出错误。

2. 视频选取的问题

   - 一般我们从相册选取视频之后回通过info[UIImagePickerControllerMediaURL]来获取路径，但是经过测试有些视频并不存在这个key值。我碰到的情况就是其他APP保存在相册，然后我的APP在选取是不存在这个key的。所以选取视频的时候我做了处理，没有key值得缓存至沙盒路径下（网上Demo很多）。

     ```objective-c
     - (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info使用
     ```



### 视频配音

思路：视频配音功能是将原视频的视频跟声道分离出来，自己录制声音，然后将所得音频跟原视频的视频进行合成新的视频导出。JWVideoDubVC跟JWVideoEditManage、JWAudioEditManage这两个类是处理配音业务的，小伙伴可以自行根据需求修改。



具体实现我在Demo里面加了好多注释，需要的可以直接读下源码就行了。使用简单方便，能满足大多数此需求的业务。  