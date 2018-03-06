//
//  UIView+DCUIViewCommon.m
//  循环滚动图片
//
//  Created by wenhua on 2018/3/6.
//  Copyright © 2018年 wenhua. All rights reserved.
//

#import "UIView+DCUIViewCommon.h"

@implementation UIView (DCUIViewCommon)

- (void)setDC_origin:(CGPoint)DC_origin {
    CGRect frame = self.frame;
    frame.origin = DC_origin;
    self.frame = frame;
}

- (CGPoint)DC_origin {
    return self.frame.origin;
}

- (void)setDC_originX:(CGFloat)DC_originX {
    self.DC_origin = CGPointMake(DC_originX, self.DC_originY);
}

- (CGFloat)DC_originX {
    return self.DC_origin.x;
}

- (void)setDC_originY:(CGFloat)DC_originY {
    self.DC_origin = CGPointMake(self.DC_originX, DC_originY);
}

- (CGFloat)DC_originY {
    return self.DC_origin.y;
}

- (void)setDC_rightX:(CGFloat)DC_rightX {
    CGRect frame = self.frame;
    frame.origin.x = DC_rightX - frame.size.width;
    self.frame = frame;
}

- (CGFloat)DC_rightX {
    return self.DC_width + self.DC_originX;
}

- (void)setDC_width:(CGFloat)DC_width {
    CGRect frame = self.frame;
    frame.size.width = DC_width;
    self.frame = frame;
}

- (CGFloat)DC_width {
    return self.frame.size.width;
}

- (void)setDC_size:(CGSize)DC_size {
    CGRect frame = self.frame;
    frame.size = DC_size;
    self.frame = frame;
}

- (CGSize)DC_size {
    return self.frame.size;
}

- (void)setDC_height:(CGFloat)DC_height {
    CGRect frame = self.frame;
    frame.size.height = DC_height;
    self.frame = frame;
}

- (CGFloat)DC_height {
    return self.frame.size.height;
}

- (void)setDC_bottomY:(CGFloat)DC_bottomY {
    CGRect frame = self.frame;
    frame.origin.y = DC_bottomY - frame.size.height;
    self.frame = frame;
}

- (CGFloat)DC_bottomY {
    return self.frame.size.height + self.frame.origin.y;
}

- (void)setDC_centerX:(CGFloat)DC_centerX {
    self.center = CGPointMake(DC_centerX, self.center.y);
}

- (CGFloat)DC_centerX {
    return self.center.x;
}

- (void)setDC_centerY:(CGFloat)DC_centerY {
    self.center = CGPointMake(self.center.x, DC_centerY);
}

- (CGFloat)DC_centerY {
    return self.center.y;
}

- (void)setDC_corneradus:(CGFloat)DC_corneradus {
    self.layer.cornerRadius = DC_corneradus;
}

- (CGFloat)DC_corneradus {
    return self.layer.cornerRadius;
}

- (void)setDC_borderColor:(UIColor *)DC_borderColor {
    self.layer.borderColor = DC_borderColor.CGColor;
}

- (UIColor *)DC_borderColor {
    return [UIColor colorWithCGColor:self.layer.borderColor];
}

- (void)setDC_borderWidth:(CGFloat)DC_borderWidth {
    self.layer.borderWidth = DC_borderWidth;
}

- (CGFloat)DC_borderWidth {
    return self.layer.borderWidth;
}
@end
