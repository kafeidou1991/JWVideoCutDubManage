//
//  JWVideoLineView.m
//  JWVideoEdit
//
//  Created by 张竟巍 on 2018/7/31.
//  Copyright © 2018年 ACAA. All rights reserved.
//

#import "JWVideoLineView.h"

@implementation JWVideoLineView

-(void)setBeginPoint:(CGPoint)beginPoint{
    _beginPoint = beginPoint;
    [self setNeedsDisplay];
}
-(void)setEndPoint:(CGPoint)endPoint{
    _endPoint = endPoint;
    [self setNeedsDisplay];
}
- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, 3);
    CGContextSetStrokeColorWithColor(context, [UIColor colorWithWhite:0.9 alpha:1].CGColor);
    CGContextMoveToPoint(context, self.beginPoint.x, self.beginPoint.y);
    CGContextAddLineToPoint(context, self.endPoint.x, self.endPoint.y);
    CGContextStrokePath(context);
}


@end
