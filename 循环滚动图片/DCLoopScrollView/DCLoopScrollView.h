//
//  DCLoopScrollView.h
//  循环滚动图片
//
//  Created by wenhua on 2018/3/6.
//  Copyright © 2018年 wenhua. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <UIKit/UIKit.h>

#pragma                   ------------DCPageControl-------------

@interface DCPageControl : UIPageControl

typedef void (^DCPageControlValueChangedBlock)(NSInteger clickAtIndex);

@property (nonatomic, copy) DCPageControlValueChangedBlock valueChangedBlock;

@end


#pragma                   ------------DCLoadImageView-------------

@class DCLoadImageView;

typedef void (^DCTapImageViewBlock)(DCLoadImageView *imageView);
typedef void (^DCImageBlock)(UIImage *image);

@interface DCLoadImageView : UIImageView

@property (nonatomic, assign) BOOL animated;

@property (nonatomic, assign) BOOL isCircle;

@property (nonatomic, copy) DCImageBlock completion;

@property (nonatomic, copy) DCTapImageViewBlock tapImageViewBlock;

/**
 *    指定URL下载图片失败时，重试的次数，默认为2次
 */
@property (nonatomic, assign) NSUInteger attemptToReloadTimesForFailedURL;

/**
 *    是否自动将下载到的图片裁剪为UIImageView的size。默认为NO。
 *  若设置为YES，则在下载成功后只存储裁剪后的image
 */
@property (nonatomic, assign) BOOL shouldAutoClipImageToViewSize;

- (void)setImageWithURLString:(NSString *)url placeholderImage:(NSString *)placeholderImage;
- (void)setImageWithURLString:(NSString *)url placeholder:(UIImage *)placeholderImage;
- (void)setImageWithURLString:(NSString *)url
                  placeholder:(UIImage *)placeholderImage
                   completion:(void (^)(UIImage *image))completion;
- (void)setImageWithURLString:(NSString *)url
             placeholderImage:(NSString *)placeholderImage
                   completion:(void (^)(UIImage *image))completion;

- (void)cancelRequest;

/**
 *    此处公开此API，是方便大家可以在别的地方使用。等比例剪裁图片大小到指定的size
 *
 *    @param image 剪裁前的图片
 *    @param size    最终图片大小
 *  @param isScaleToMax 是取最大比例还是最小比例，YES表示取最大比例
 *
 *    @return 裁剪后的图片
 */
+ (UIImage *)clipImage:(UIImage *)image toSize:(CGSize)size isScaleToMax:(BOOL)isScaleToMax;
@end



#pragma                   -------------DCLoopScrollView------------

typedef NS_ENUM(NSInteger, DCPageControlAlignment) {
    /**
     *  For the center type, only show the page control without any text
     */
    kPageControlAlignCenter = 1 << 1,
    /**
     *  For the align right type, will show the page control and show the ad text
     */
    kPageControlAlignRight  = 1 << 2
};

@class DCLoopScrollView;

typedef void (^DCLoopScrollViewDidSelectItemBlock)(NSInteger atIndex);

typedef void (^DCLoopScrollViewDidScrollBlock)(NSInteger toIndex);

@interface DCLoopScrollView : UIView

@property (nonatomic, strong) UIImage *placeholder;

@property (nonatomic, strong, readonly) DCPageControl *pageControl;

@property (nonatomic, assign) DCPageControlAlignment alignment;

@property (nonatomic, strong) NSArray *imageUrls;

@property (nonatomic, assign) BOOL pageControlEnabled;

@property (nonatomic, strong) NSArray *adTitles;

/**
 *    是否自动将下载到的图片裁剪为UIImageView的size。默认为NO。
 *  若设置为YES，则在下载成功后只存储裁剪后的image
 */
@property (nonatomic, assign) BOOL shouldAutoClipImageToViewSize;

+ (instancetype)loopScrollViewWithFrame:(CGRect)frame
                              imageUrls:(NSArray *)imageUrls
                           timeInterval:(NSTimeInterval)timeInterval
                              didSelect:(DCLoopScrollViewDidSelectItemBlock)didSelect
                              didScroll:(DCLoopScrollViewDidScrollBlock)didScroll;


- (void)pauseTimer;

- (void)startTimer;

/**
 *    清理掉本地缓存
 */
- (void)clearImagesCache;

/**
 *    获取图片缓存的占用的总大小（如果有需要计算缓存大小的需求时，可以调用这个API来获取）
 *
 *    @return 大小/bytes
 */
- (unsigned long long)imagesCacheSize;
@end
