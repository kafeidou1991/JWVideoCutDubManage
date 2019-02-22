//
//  JWVideoThumbView.m
//  JWVideoEdit
//
//  Created by 张竟巍 on 2018/7/31.
//  Copyright © 2018年 ACAA. All rights reserved.
//

#import "JWVideoThumbView.h"
#import "JWVideoLineView.h"

@interface JWVideoThumbView () {
    CGPoint _beginPoint;
}
@property(nonatomic,strong) JWVideoSlideView *leftHaft;
@property(nonatomic,strong) JWVideoSlideView *rightHaft;
@property(nonatomic,strong) JWVideoLineView *topLine;
@property(nonatomic,strong) JWVideoLineView *bottomLine;
@property(nonatomic,strong) UIView *leftMaskView;
@property(nonatomic,strong) UIView *rightMaskView;
@end

@implementation JWVideoThumbView

-(instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        [self initSubViews:frame];
    }
    return self;
}
-(instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initSubViews:self.frame];
    }
    return self;
}
- (void)initSubViews:(CGRect)frame{
    CGFloat height = CGRectGetHeight(frame);
    CGFloat width = CGRectGetWidth(frame);
    _minGap = 30;
    CGFloat widthHaft = 10;
    CGFloat heightLine = 3;
    _leftHaft = [[JWVideoSlideView alloc] initWithFrame:CGRectMake(0, 0, widthHaft, height)];
    _leftHaft.alpha = 0.8;
    _leftHaft.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1];
    _leftHaft.rightEdgeInset = 20;
    _leftHaft.lefEdgeInset = 5;
    __weak typeof(self) this = self;
    [_leftHaft setBlockMove:^(CGPoint point) {
        CGFloat maxX = this.rightHaft.frame.origin.x-this.minGap;
        if (point.x<maxX) {
            this.topLine.beginPoint = CGPointMake(point.x, heightLine/2.0);
            this.bottomLine.beginPoint = CGPointMake(point.x, heightLine/2.0);
            this.leftHaft.frame = CGRectMake(point.x, 0, widthHaft, height);
            this.leftMaskView.frame = CGRectMake(0, 0, point.x, height);
            if (this.blockSeekOffLeft) {
                this.blockSeekOffLeft(point.x);
            }
        }
    }];
    
    [_leftHaft setBlockMoveEnd:^{
        if (this.blockMoveEnd) {
            this.blockMoveEnd();
        }
    }];
    _rightHaft = [[JWVideoSlideView alloc] initWithFrame:CGRectMake(width-widthHaft, 0, widthHaft, height)];
    _rightHaft.alpha = 0.8;
    _rightHaft.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1];
    _rightHaft.lefEdgeInset = 20;
    _rightHaft.rightEdgeInset = 5;
    [_rightHaft setBlockMove:^(CGPoint point) {
        CGFloat minX = this.leftHaft.frame.origin.x+this.minGap+CGRectGetWidth(this.rightHaft.bounds);
        if (point.x>=minX) {
            this.topLine.endPoint = CGPointMake(point.x-widthHaft, heightLine/2.0);
            this.bottomLine.endPoint = CGPointMake(point.x-widthHaft, heightLine/2.0);
            this.rightHaft.frame = CGRectMake(point.x, 0, widthHaft, height);
            this.rightMaskView.frame = CGRectMake(point.x+widthHaft, 0, width-point.x-widthHaft, height);
            if (this.blockSeekOffRight) {
                this.blockSeekOffRight(point.x);
            }
        }
    }];
    [_rightHaft setBlockMoveEnd:^{
        if (this.blockMoveEnd) {
            this.blockMoveEnd();
        }
    }];
    _topLine = [[JWVideoLineView alloc] init];
    _topLine.alpha = 0.8;
    _topLine.frame = CGRectMake(widthHaft, 0, width-2*widthHaft, heightLine);
    _topLine.beginPoint = CGPointMake(0, heightLine/2.0);
    _topLine.endPoint = CGPointMake(CGRectGetWidth(_topLine.bounds), heightLine/2.0);
    _topLine.backgroundColor = [UIColor clearColor];
    [self addSubview:_topLine];
    
    _bottomLine = [[JWVideoLineView alloc] init];
    _bottomLine.alpha = 0.8;
    _bottomLine.frame = CGRectMake(widthHaft, height-heightLine, width-2*widthHaft, heightLine);
    _bottomLine.beginPoint = CGPointMake(0, heightLine/2.0);
    _bottomLine.endPoint = CGPointMake(CGRectGetWidth(_bottomLine.bounds), heightLine/2.0);
    _bottomLine.backgroundColor = [UIColor clearColor];
    [self addSubview:_bottomLine];
    
    [self addSubview:_leftHaft];
    [self addSubview:_rightHaft];
    
    self.leftMaskView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, height)];
    self.leftMaskView.backgroundColor = [UIColor blackColor];
    self.leftMaskView.alpha = 0.3;
    [self addSubview:self.leftMaskView];
    self.rightMaskView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, height)];
    self.rightMaskView.backgroundColor = [UIColor blackColor];
    self.rightMaskView.alpha = 0.3;
    [self addSubview:self.rightMaskView];
}
-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    UITouch *touch = touches.anyObject;
    _beginPoint = [touch locationInView:self];
    
}


@end
