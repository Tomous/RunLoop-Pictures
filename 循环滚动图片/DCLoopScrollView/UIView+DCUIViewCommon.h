//
//  UIView+DCUIViewCommon.h
//  循环滚动图片
//
//  Created by wenhua on 2018/3/6.
//  Copyright © 2018年 wenhua. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (DCUIViewCommon)
/**
 * @brief Shortcut for frame.origin.x.
 *        Sets frame.origin.x = originX
 */
@property (nonatomic) CGFloat DC_originX;

/**
 * @brief Shortcut for frame.origin.y
 *        Sets frame.origin.y = originY
 */
@property (nonatomic) CGFloat DC_originY;

/**
 * @brief Shortcut for frame.origin.x + frame.size.width
 *       Sets frame.origin.x = rightX - frame.size.width
 */
@property (nonatomic) CGFloat DC_rightX;

/**
 * @brief Shortcut for frame.origin.y + frame.size.height
 *        Sets frame.origin.y = bottomY - frame.size.height
 */
@property (nonatomic) CGFloat DC_bottomY;

/**
 * @brief Shortcut for frame.size.width
 *        Sets frame.size.width = width
 */
@property (nonatomic) CGFloat DC_width;

/**
 * @brief Shortcut for frame.size.height
 *        Sets frame.size.height = height
 */
@property (nonatomic) CGFloat DC_height;

/**
 * @brief Shortcut for center.x
 * Sets center.x = centerX
 */
@property (nonatomic) CGFloat DC_centerX;

/**
 * @brief Shortcut for center.y
 *        Sets center.y = centerY
 */
@property (nonatomic) CGFloat DC_centerY;

/**
 * @brief Shortcut for frame.origin
 */
@property (nonatomic) CGPoint DC_origin;

/**
 * @brief Shortcut for frame.size
 */
@property (nonatomic) CGSize DC_size;

/**
 *  Get/Set the control's corneradus
 *  Default is 0.0
 */
@property (nonatomic, assign) CGFloat DC_corneradus;

/**
 *  Get/Set the control's border color
 *  Default is [UIColor lightGrayColor]
 */
@property (nonatomic, strong) UIColor *DC_borderColor;

/**
 *  Get/Set the control's border width
 *  Default is 0.0
 */
@property (nonatomic, assign) CGFloat DC_borderWidth;

@end
