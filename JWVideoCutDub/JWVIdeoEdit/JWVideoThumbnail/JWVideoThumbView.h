//
//  JWVideoThumbView.h
//  JWVideoEdit
//
//  Created by 张竟巍 on 2018/7/31.
//  Copyright © 2018年 ACAA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JWVideoSlideView.h"

typedef void(^BlockSeekOff)(CGFloat offX);
@interface JWVideoThumbView : UIView

@property (nonatomic,copy)BlockSeekOff blockSeekOffLeft;
@property (nonatomic,copy)BlockSeekOff blockSeekOffRight;
@property (nonatomic,copy)BlockMoveEnd blockMoveEnd;
@property (nonatomic,assign)CGFloat minGap;

@end
