//
//  DCLoopScrollView.m
//  循环滚动图片
//
//  Created by wenhua on 2018/3/6.
//  Copyright © 2018年 wenhua. All rights reserved.
//

#import "DCLoopScrollView.h"
#import <objc/message.h>
#import <objc/runtime.h>
#import <CommonCrypto/CommonDigest.h>
#import "UIView+DCUIViewCommon.h"


#pragma                   ------------DCPageControl-------------
@implementation DCPageControl

- (instancetype)init {
    if (self = [super init]) {
        // To Do:
        // set any default properties here
        [self addTarget:self
                 action:@selector(onPageControlValueChanged:)
       forControlEvents:UIControlEventValueChanged];
    }
    
    return self;
}

- (void)onPageControlValueChanged:(DCPageControl *)sender {
    if (self.valueChangedBlock) {
        self.valueChangedBlock(sender.currentPage);
    }
}
@end


#pragma                   ------------DCImageDownloader-------------
typedef void (^DCDownLoadDataCallBack)(NSData *data, NSError *error);
typedef void (^DCDownloadProgressBlock)(unsigned long long total, unsigned long long current);

/**
 *    图片下载器，没有直接使用NSURLSession之类的，是因为希望这套库可以支持iOS6
 */
@interface DCImageDownloader : NSObject<NSURLConnectionDataDelegate>

@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, strong) NSMutableData *data;

@property (nonatomic, assign) unsigned long long totalLength;
@property (nonatomic, assign) unsigned long long currentLength;

@property (nonatomic, copy) DCDownloadProgressBlock progressBlock;
@property (nonatomic, copy) DCDownLoadDataCallBack callbackOnFinished;

- (void)startDownloadImageWithUrl:(NSString *)url
                         progress:(DCDownloadProgressBlock)progress
                         finished:(DCDownLoadDataCallBack)finished;

@end

@implementation DCImageDownloader

- (void)startDownloadImageWithUrl:(NSString *)url
                         progress:(DCDownloadProgressBlock)progress
                         finished:(DCDownLoadDataCallBack)finished {
    self.progressBlock = progress;
    self.callbackOnFinished = finished;
    
    if ([NSURL URLWithString:url] == nil) {
        if (finished) {
            finished(nil, [NSError errorWithDomain:@"henishuo.com"
                                              code:101
                                          userInfo:@{@"errorMessage": @"URL不正确"}]);
        }
        return;
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]
                                                           cachePolicy:NSURLRequestReturnCacheDataElseLoad
                                                       timeoutInterval:60];
    [request addValue:@"image/*" forHTTPHeaderField:@"Accept"];
    
    self.connection = [NSURLConnection connectionWithRequest:request delegate:self];
}

#pragma mark - NSURLConnectionDataDelegate
- (NSMutableData *)data {
    if (_data == nil) {
        _data = [[NSMutableData alloc] init];
    }
    
    return _data;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    [self.data setLength:0];
    self.totalLength = response.expectedContentLength;
    self.currentLength = 0;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.data appendData:data];
    self.currentLength += data.length;
    
    if (self.progressBlock) {
        self.progressBlock(self.totalLength, self.currentLength);
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    if (self.progressBlock) {
        self.progressBlock(self.totalLength, self.currentLength);
    }
    
    if (self.callbackOnFinished) {
        self.callbackOnFinished([self.data copy], nil);
        
        // 防止重复调用
        self.callbackOnFinished = nil;
    }
    NSLog(@"%s %@   %p", __FUNCTION__, connection.currentRequest.URL.absoluteString, self);
    
    [self.data setLength:0];
    self.data = nil;
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    if ([error code] != NSURLErrorCancelled) {
        if (self.callbackOnFinished) {
            self.callbackOnFinished(nil, error);
        }
        
        self.callbackOnFinished = nil;
    }
    
    [self.data setLength:0];
    self.data = nil;
    NSLog(@"%s", __FUNCTION__);
}

@end


#pragma                   ------------NSString (md5)-------------
@interface NSString (md5)

+ (NSString *)DC_md5:(NSString *)string;

@end

@implementation NSString (md5)

+ (NSString *)DC_md5:(NSString *)string {
    if (string == nil || [string length] == 0) {
        return nil;
    }
    
    unsigned char digest[CC_MD5_DIGEST_LENGTH], i;
    CC_MD5([string UTF8String], (int)[string lengthOfBytesUsingEncoding:NSUTF8StringEncoding], digest);
    NSMutableString *ms = [NSMutableString string];
    
    for (i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [ms appendFormat:@"%02x", (int)(digest[i])];
    }
    
    return [ms copy];
}

@end


#pragma                   ------------DCImageCache-------------
@interface DCImageCache : NSCache

@property (nonatomic, assign) NSUInteger failTimes;

- (BOOL)cacheImage:(UIImage *)image forRequest:(NSURLRequest *)request;
- (BOOL)cacheImage:(UIImage *)image forUrl:(NSString *)url;
- (UIImage *)cacheImageForRequest:(NSURLRequest *)request;

@end

@implementation DCImageCache

- (UIImage *)cacheImageForRequest:(NSURLRequest *)request {
    if (request == nil || ![request isKindOfClass:[NSURLRequest class]]) {
        return nil;
    }
    
    return [self objectForKey:[NSString DC_md5:request.URL.absoluteString]];
}

- (BOOL)cacheImage:(UIImage *)image forUrl:(NSString *)url {
    if (image != nil && ![image isKindOfClass:[NSNull class]]) {
        [self setObject:image forKey:url];
        return YES;
    }
    
    return NO;
}

- (BOOL)cacheImage:(UIImage *)image forRequest:(NSURLRequest *)request {
    if (request) {
        NSString *url = [NSString DC_md5:request.URL.absoluteString];
        return [self cacheImage:image forUrl:url];
    }
    
    return NO;
}

@end

#pragma                   ------------UIApplication (DCCacheImage)-------------
@interface UIApplication (DCCacheImage)

@property (nonatomic, strong, readonly) NSMutableDictionary *DC_cacheImages;

- (UIImage *)DC_cacheImageForRequest:(NSURLRequest *)request;
- (void)DC_cacheImage:(UIImage *)image forRequest:(NSURLRequest *)request;
- (void)DC_cacheFailRequest:(NSURLRequest *)request;
- (NSUInteger)DC_failTimesForRequest:(NSURLRequest *)request;

@end

static char *s_DC_cacheimages = "s_DC_cacheimages";

@implementation UIApplication (DCCacheImage)

- (void)DC_clearCache {
    [self.DC_cacheImages removeAllObjects];
    
    objc_setAssociatedObject(self, s_DC_cacheimages, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)DC_clearDiskCaches {
    NSString *directoryPath = [NSHomeDirectory() stringByAppendingString:@"/Documents/DCLoopScollViewImages"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:directoryPath isDirectory:nil]) {
        NSError *error = nil;
        [[NSFileManager defaultManager] removeItemAtPath:directoryPath error:&error];
        
        if (error) {
            NSLog(@"clear caches error: %@", error);
        } else {
            NSLog(@"clear caches ok");
        }
    }
    
    [self DC_clearCache];
}

- (UIImage *)DC_cacheImageForRequest:(NSURLRequest *)request {
    DCImageCache *cache = [self.DC_cacheImages objectForKey:[NSString DC_md5:request.URL.absoluteString]];
    if (cache) {
        return [cache cacheImageForRequest:request];
    }
    
    return nil;
}

- (NSUInteger)DC_failTimesForRequest:(NSURLRequest *)request {
    DCImageCache *cache = [self.DC_cacheImages objectForKey:[NSString DC_md5:request.URL.absoluteString]];
    
    if (cache) {
        return cache.failTimes;
    }
    
    return 0;
}

- (void)DC_cacheFailRequest:(NSURLRequest *)request {
    DCImageCache *cache = [self.DC_cacheImages objectForKey:[NSString DC_md5:request.URL.absoluteString]];
    if (!cache) {
        cache = [[DCImageCache alloc] init];
    }
    
    cache.failTimes += 1;
    [self.DC_cacheImages setObject:cache forKey:[NSString DC_md5:request.URL.absoluteString]];
}

- (void)DC_cacheImage:(UIImage *)image forRequest:(NSURLRequest *)request {
    [self DC_cacheImage:image forKey:[NSString DC_md5:request.URL.absoluteString]];
    [self DC_cacheToDiskForData:UIImagePNGRepresentation(image) request:request];
}

- (void)DC_cacheImage:(UIImage *)image forKey:(NSString *)key {
    if (self.DC_cacheImages[key]) {
        return;
    }
    
    DCImageCache *cache = [[DCImageCache alloc] init];
    [cache cacheImage:image forUrl:key];
    [self.DC_cacheImages setObject:cache forKey:key];
}

- (NSMutableDictionary *)DC_cacheImages {
    NSMutableDictionary *caches = objc_getAssociatedObject(self, s_DC_cacheimages);
    
    if (caches == nil) {
        caches = [[NSMutableDictionary alloc] init];
        
        // Try to get datas from disk
        NSString *directoryPath = [NSHomeDirectory() stringByAppendingString:@"/Documents/DCLoopScollViewImages"];
        BOOL isDir = NO;
        if ([[NSFileManager defaultManager] fileExistsAtPath:directoryPath isDirectory:&isDir]) {
            if (isDir) {
                NSError *error = nil;
                NSArray *array = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:directoryPath error:&error];
                
                if (error == nil) {
                    for (NSString *subpath in array) {
                        NSData *data = [[NSFileManager defaultManager] contentsAtPath:[directoryPath stringByAppendingPathComponent:subpath]];
                        if (data) {
                            UIImage *image = [UIImage imageWithData:data];
                            if (image) {
                                DCImageCache *cache = [[DCImageCache alloc] init];
                                [cache cacheImage:image forUrl:subpath];
                                [caches setObject:cache forKey:subpath];
                            }
                        }
                    }
                }
            }
        }
        
        objc_setAssociatedObject(self, s_DC_cacheimages, caches, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    return caches;
}

- (void)DC_cacheToDiskForData:(NSData *)data request:(NSURLRequest *)request {
    if (data == nil || request == nil) {
        return;
    }
    
    NSString *directoryPath = [NSHomeDirectory() stringByAppendingString:@"/Documents/DCLoopScollViewImages"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:directoryPath isDirectory:nil]) {
        NSError *error = nil;
        [[NSFileManager defaultManager] createDirectoryAtPath:directoryPath
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:&error];
        if (error) {
            NSLog(@"create cache dir error: %@", error);
            return;
        }
    }
    
    NSString *path = [NSString stringWithFormat:@"%@/%@",
                      directoryPath,
                      [NSString DC_md5:request.URL.absoluteString]];
    BOOL isOk = [[NSFileManager defaultManager] createFileAtPath:path contents:data attributes:nil];
    if (isOk) {
        NSLog(@"cache file ok for request: %@", [NSString DC_md5:request.URL.absoluteString]);
    } else {
        NSLog(@"cache file error for request: %@", [NSString DC_md5:request.URL.absoluteString]);
    }
}

@end


#pragma                   ------------DCLoadImageView-------------

#define kImageWithName(Name) ([UIImage imageNamed:Name])
#define kAnimationDuration 1.0

@interface DCLoadImageView () {
@private
    BOOL                     _isAnimated;
    UITapGestureRecognizer   *_tap;
    __weak DCImageDownloader *_imageDownloader;
}

@end

@implementation DCLoadImageView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self configureLayout];
    }
    return self;
}

- (instancetype)init {
    return [self initWithFrame:CGRectZero];
}

- (instancetype)initWithImage:(UIImage *)image {
    if (self = [super initWithImage:image]) {
        [self configureLayout];
    }
    return self;
}

- (void)configureLayout {
    self.contentMode = UIViewContentModeScaleAspectFill;
    self.animated = YES;
    self.DC_borderColor = [UIColor lightGrayColor];
    self.DC_borderWidth = 0.0;
    self.DC_corneradus = 0.0;
    self.isCircle = NO;
    
    self.attemptToReloadTimesForFailedURL = 2;
    self.shouldAutoClipImageToViewSize = NO;
}

- (void)setImage:(UIImage *)image isFromCache:(BOOL)isFromCache {
    self.image = image;
    
    if (!isFromCache && _isAnimated) {
        CATransition *animation = [CATransition animation];
        [animation setDuration:0.65f];
        [animation setType:kCATransitionFade];
        animation.removedOnCompletion = YES;
        [self.layer addAnimation:animation forKey:@"transition"];
    }
}

- (void)setAnimated:(BOOL)animated {
    _isAnimated = animated;
    return;
}

- (BOOL)animated {
    return _isAnimated;
}

- (void)setIsCircle:(BOOL)isCircle {
    _isCircle = isCircle;
    
    if (_isCircle) {
        CGFloat w = MIN(self.DC_width, self.DC_height);
        self.DC_size = CGSizeMake(w, w);
        self.DC_corneradus = w / 2;
        self.clipsToBounds = YES;
    } else {
        self.clipsToBounds = NO;
    }
}

- (void)setTapImageViewBlock:(DCTapImageViewBlock)tapImageViewBlock {
    if (_tapImageViewBlock != tapImageViewBlock) {
        _tapImageViewBlock = [tapImageViewBlock copy];
    }
    
    if (_tapImageViewBlock == nil) {
        if (_tap != nil) {
            [self removeGestureRecognizer:_tap];
            self.userInteractionEnabled = NO;
        }
    } else {
        if (_tap == nil) {
            _tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTap:)];
            [self addGestureRecognizer:_tap];
            self.userInteractionEnabled = YES;
        }
    }
}

- (void)onTap:(UITapGestureRecognizer *)tap {
    if (self.tapImageViewBlock) {
        self.tapImageViewBlock((DCLoadImageView *)tap.view);
    }
}

- (void)setImageWithURLString:(NSString *)url
             placeholderImage:(NSString *)placeholderImage {
    return [self setImageWithURLString:url placeholderImage:placeholderImage completion:nil];
}

- (void)setImageWithURLString:(NSString *)url placeholder:(UIImage *)placeholderImage {
    return [self setImageWithURLString:url placeholder:placeholderImage completion:nil];
}

- (void)setImageWithURLString:(NSString *)url
                  placeholder:(UIImage *)placeholderImage
                   completion:(void (^)(UIImage *image))completion {
    [self.layer removeAllAnimations];
    self.completion = completion;
    
    
    if (url == nil
        || [url isKindOfClass:[NSNull class]]
        || (![url hasPrefix:@"http://"] && ![url hasPrefix:@"https://"])) {
        [self setImage:placeholderImage isFromCache:YES];
        
        if (completion) {
            self.completion(self.image);
        }
        return;
    }
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    [self downloadWithReqeust:request holder:placeholderImage];
}

- (void)downloadWithReqeust:(NSURLRequest *)theRequest holder:(UIImage *)holder {
    UIImage *cachedImage = [[UIApplication sharedApplication] DC_cacheImageForRequest:theRequest];
    
    if (cachedImage) {
        [self setImage:cachedImage isFromCache:YES];
        
        if (self.completion) {
            self.completion(cachedImage);
        }
        return;
    }
    
    [self setImage:holder isFromCache:YES];
    
    if ([[UIApplication sharedApplication] DC_failTimesForRequest:theRequest] >= self.attemptToReloadTimesForFailedURL) {
        return;
    }
    
    [self cancelRequest];
    _imageDownloader = nil;
    
    __weak __typeof(self) weakSelf = self;
    
    DCImageDownloader *downloader = [[DCImageDownloader alloc] init];
    _imageDownloader = downloader;
    [downloader startDownloadImageWithUrl:theRequest.URL.absoluteString progress:nil finished:^(NSData *data, NSError *error) {
        // 成功
        if (data != nil && error == nil) {
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                UIImage *image = [UIImage imageWithData:data];
                UIImage *finalImage = image;
                
                if (image) {
                    if (weakSelf.shouldAutoClipImageToViewSize) {
                        // 剪裁
                        if (fabs(weakSelf.frame.size.width - image.size.width) != 0
                            && fabs(weakSelf.frame.size.height - image.size.height) != 0) {
                            finalImage = [DCLoadImageView clipImage:image toSize:weakSelf.frame.size isScaleToMax:NO];
                        }
                    }
                    
                    [[UIApplication sharedApplication] DC_cacheImage:finalImage forRequest:theRequest];
                } else {
                    [[UIApplication sharedApplication] DC_cacheFailRequest:theRequest];
                }
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (finalImage) {
                        [weakSelf setImage:finalImage isFromCache:NO];
                        
                        if (weakSelf.completion) {
                            weakSelf.completion(weakSelf.image);
                        }
                    } else {// error data
                        if (weakSelf.completion) {
                            weakSelf.completion(weakSelf.image);
                        }
                    }
                });
            });
        } else { // error
            [[UIApplication sharedApplication] DC_cacheFailRequest:theRequest];
            
            if (weakSelf.completion) {
                weakSelf.completion(weakSelf.image);
            }
        }
    }];
}

- (void)setImageWithURLString:(NSString *)url
             placeholderImage:(NSString *)placeholderImage
                   completion:(void (^)(UIImage *image))completion {
    [self setImageWithURLString:url placeholder:kImageWithName(placeholderImage) completion:completion];
}

- (void)cancelRequest {
    [_imageDownloader.connection cancel];
}

+ (UIImage *)clipImage:(UIImage *)image toSize:(CGSize)size isScaleToMax:(BOOL)isScaleToMax {
    CGFloat scale =  [UIScreen mainScreen].scale;
    
    UIGraphicsBeginImageContextWithOptions(size, NO, scale);
    
    CGSize aspectFitSize = CGSizeZero;
    if (image.size.width != 0 && image.size.height != 0) {
        CGFloat rateWidth = size.width / image.size.width;
        CGFloat rateHeight = size.height / image.size.height;
        
        CGFloat rate = isScaleToMax ? MAX(rateHeight, rateWidth) : MIN(rateHeight, rateWidth);
        aspectFitSize = CGSizeMake(image.size.width * rate, image.size.height * rate);
    }
    
    [image drawInRect:CGRectMake(0, 0, aspectFitSize.width, aspectFitSize.height)];
    UIImage *finalImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return finalImage;
}
@end


#pragma                   ------------DCCollectionCell-------------

NSString * const kCellIdentifier = @"ReuseCellIdentifier";

@interface DCCollectionCell : UICollectionViewCell

@property (nonatomic, strong) DCLoadImageView *imageView;
@property (nonatomic, strong) UILabel          *titleLabel;
@property (nonatomic, assign) BOOL             isDragging;

@end

@implementation DCCollectionCell

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.imageView = [[DCLoadImageView alloc] init];
        [self addSubview:self.imageView];
        self.imageView.isCircle = YES;
        
        self.titleLabel = [[UILabel alloc] init];
        self.titleLabel.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
        //      self.titleLabel.backgroundColor = [UIColor clearColor];
        self.titleLabel.hidden = YES;
        self.titleLabel.textColor = [UIColor whiteColor];
        self.titleLabel.font = [UIFont systemFontOfSize:13];
        [self addSubview:self.titleLabel];
        self.titleLabel.layer.masksToBounds = YES;
    }
    
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.imageView.frame = self.bounds;
    self.titleLabel.frame = CGRectMake(0, self.frame.size.height - 30, self.frame.size.width, 30);
    self.titleLabel.hidden = self.titleLabel.text.length > 0 ? NO : YES;
}

@end


#pragma                   ------------DCLoopScrollView-------------

@interface DCLoopScrollView () <UICollectionViewDataSource, UICollectionViewDelegate> {
    DCPageControl *_pageControl;
}

@property (nonatomic, copy) DCLoopScrollViewDidSelectItemBlock didSelectItemBlock;
@property (nonatomic, copy) DCLoopScrollViewDidScrollBlock didScrollBlock;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UICollectionViewFlowLayout *layout;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, assign) NSInteger totalPageCount;

@property (nonatomic, assign) NSInteger previousPageIndex;
@property (nonatomic, assign) NSTimeInterval timeInterval;

@end

@implementation DCLoopScrollView
- (void)dealloc {
    NSLog(@"DCloopscrollview dealloc");
    [[NSNotificationCenter defaultCenter] removeObserver:[UIApplication sharedApplication]
                                                    name:UIApplicationDidReceiveMemoryWarningNotification
                                                  object:nil];
}

- (void)pauseTimer {
    if (self.timer) {
        [self.timer setFireDate:[NSDate distantFuture]];
    }
}

- (void)startTimer {
    if (self.timer) {
        [self.timer performSelector:@selector(setFireDate:)
                         withObject:[NSDate distantPast]
                         afterDelay:self.timeInterval];
    }
}

- (DCPageControl *)pageControl {
    return _pageControl;
}

- (void)removeFromSuperview {
    [self.timer invalidate];
    self.timer = nil;
    
    [super removeFromSuperview];
}

+ (instancetype)loopScrollViewWithFrame:(CGRect)frame
                              imageUrls:(NSArray *)imageUrls
                           timeInterval:(NSTimeInterval)timeInterval
                              didSelect:(DCLoopScrollViewDidSelectItemBlock)didSelect
                              didScroll:(DCLoopScrollViewDidScrollBlock)didScroll {
    DCLoopScrollView *loopView = [[DCLoopScrollView alloc] initWithFrame:frame];
    loopView.imageUrls = imageUrls;
    loopView.timeInterval = timeInterval;
    loopView.didScrollBlock = didScroll;
    loopView.didSelectItemBlock = didSelect;
    
    return loopView;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.timeInterval = 5.0;
        self.alignment = kPageControlAlignCenter;
        [self configCollectionView];
        
        [[NSNotificationCenter defaultCenter] addObserver:[UIApplication sharedApplication]
                                                 selector:NSSelectorFromString(@"DC_clearCache")
                                                     name:UIApplicationDidReceiveMemoryWarningNotification
                                                   object:nil];
    }
    return self;
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    
    self.layout.itemSize = frame.size;
}

- (void)configCollectionView {
    self.layout = [[UICollectionViewFlowLayout alloc] init];
    self.layout .itemSize = self.bounds.size;
    self.layout .minimumLineSpacing = 0;
    self.layout .scrollDirection = UICollectionViewScrollDirectionHorizontal;
    
    self.collectionView = [[UICollectionView alloc] initWithFrame:self.frame
                                             collectionViewLayout:self.layout];
    self.collectionView.backgroundColor = [UIColor lightGrayColor];
    self.collectionView.pagingEnabled = YES;
    self.collectionView.showsHorizontalScrollIndicator = NO;
    self.collectionView.showsVerticalScrollIndicator = NO;
    [self.collectionView  registerClass:[DCCollectionCell class]
             forCellWithReuseIdentifier:kCellIdentifier];
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    [self addSubview:self.collectionView];
}

- (void)configTimer {
    if (self.imageUrls.count <= 1) {
        return;
    }
    
    [self.timer invalidate];
    self.timer = nil;
    self.timer = [NSTimer scheduledTimerWithTimeInterval:_timeInterval
                                                  target:self
                                                selector:@selector(autoScroll)
                                                userInfo:nil
                                                 repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
}

- (void)setPageControlEnabled:(BOOL)pageControlEnabled {
    if (_pageControlEnabled != pageControlEnabled) {
        _pageControlEnabled = pageControlEnabled;
        
        if (_pageControlEnabled) {
            __weak __typeof(self) weakSelf = self;
            self.pageControl.valueChangedBlock = ^(NSInteger clickedAtIndex) {
                NSInteger curIndex = (weakSelf.collectionView.contentOffset.x
                                      + weakSelf.layout.itemSize.width * 0.5) / weakSelf.layout.itemSize.width;
                NSInteger toIndex = curIndex + (clickedAtIndex > weakSelf.previousPageIndex ? clickedAtIndex : -clickedAtIndex);
                [weakSelf.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:toIndex inSection:0]
                                                atScrollPosition:UICollectionViewScrollPositionNone
                                                        animated:YES];
                
            };
        } else {
            self.pageControl.valueChangedBlock = nil;
        }
    }
}

- (void)configPageControl {
    if (self.pageControl == nil) {
        _pageControl = [[DCPageControl alloc] init];
        self.pageControl.hidesForSinglePage = YES;
        [self addSubview:self.pageControl];
        self.pageControlEnabled = YES;
    }
    
    [self bringSubviewToFront:self.pageControl];
    self.pageControl.numberOfPages = self.imageUrls.count;
    CGSize size = [self.pageControl sizeForNumberOfPages:self.imageUrls.count];
    self.pageControl.DC_size = size;
    
    if (self.alignment == kPageControlAlignCenter) {
        self.pageControl.DC_originX = (self.DC_width - self.pageControl.DC_width) / 2.0;
    } else if (self.alignment == kPageControlAlignRight) {
        self.pageControl.DC_rightX = self.DC_width - 10;
    }
    self.pageControl.DC_originY = self.DC_height - self.pageControl.DC_height + 5;
}

- (void)setTimeInterval:(NSTimeInterval)timeInterval {
    _timeInterval = timeInterval;
    
    [self configTimer];
}

- (void)autoScroll {
    NSInteger curIndex = (self.collectionView.contentOffset.x + self.layout.itemSize.width * 0.5) / self.layout.itemSize.width;
    NSInteger toIndex = curIndex + 1;
    
    NSIndexPath *indexPath = nil;
    if (toIndex == self.totalPageCount) {
        toIndex = self.totalPageCount * 0.5;
        
        // scroll to the middle without animation, and scroll to middle with animation, so that it scrolls
        // more smoothly.
        indexPath = [NSIndexPath indexPathForItem:toIndex inSection:0];
        [self.collectionView scrollToItemAtIndexPath:indexPath
                                    atScrollPosition:UICollectionViewScrollPositionNone
                                            animated:NO];
    } else {
        indexPath = [NSIndexPath indexPathForItem:toIndex inSection:0];
    }
    
    [self.collectionView scrollToItemAtIndexPath:indexPath
                                atScrollPosition:UICollectionViewScrollPositionNone
                                        animated:YES];
}

- (void)setImageUrls:(NSArray *)imageUrls {
    if (![imageUrls isKindOfClass:[NSArray class]]) {
        return;
    }
    
    if (imageUrls == nil || imageUrls.count == 0) {
        self.collectionView.scrollEnabled = NO;
        [self pauseTimer];
        self.totalPageCount = 0;
        [self.collectionView reloadData];
        return;
    }
    
    if (_imageUrls != imageUrls) {
        _imageUrls = imageUrls;
        
        if (imageUrls.count > 1) {
            self.totalPageCount = imageUrls.count * 50;
            [self configTimer];
            [self configPageControl];
            self.collectionView.scrollEnabled = YES;
        } else {
            // If there is only one page, stop the timer and make scroll enabled to be NO.
            [self pauseTimer];
            
            self.totalPageCount = 1;
            [self configPageControl];
            self.collectionView.scrollEnabled = NO;
        }
        [self.collectionView reloadData];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (self.totalPageCount == 0) {
        return;
    }
    
    self.collectionView.frame = self.bounds;
    if (self.collectionView.contentOffset.x == 0) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:self.totalPageCount * 0.5
                                                     inSection:0];
        [self.collectionView scrollToItemAtIndexPath:indexPath
                                    atScrollPosition:UICollectionViewScrollPositionNone
                                            animated:NO];
    }
    
    [self configPageControl];
}

- (void)setAlignment:(DCPageControlAlignment)alignment {
    if (_alignment != alignment) {
        _alignment = alignment;
        
        [self configPageControl];
        [self.collectionView reloadData];
    }
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section {
    return self.totalPageCount;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    DCCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kCellIdentifier
                                                                        forIndexPath:indexPath];
    
    // 先取消之前的请求
    DCLoadImageView *preImageView = cell.imageView;
    preImageView.shouldAutoClipImageToViewSize = self.shouldAutoClipImageToViewSize;
    if ([preImageView isKindOfClass:[DCLoadImageView class]]) {
        [preImageView cancelRequest];
    }
    
    NSInteger itemIndex = indexPath.item % self.imageUrls.count;
    if (itemIndex < self.imageUrls.count) {
        NSString *urlString = self.imageUrls[itemIndex];
        if ([urlString isKindOfClass:[UIImage class]]) {
            cell.imageView.image = (UIImage *)urlString;
        } else if ([urlString hasPrefix:@"http://"]
                   || [urlString hasPrefix:@"https://"]
                   || [urlString rangeOfString:@"/"].location != NSNotFound) {
            [cell.imageView setImageWithURLString:urlString placeholder:self.placeholder];
        } else {
            cell.imageView.image = [UIImage imageNamed:urlString];
        }
    }
    
    if (self.alignment == kPageControlAlignRight && itemIndex < self.adTitles.count) {
        cell.titleLabel.text = [NSString stringWithFormat:@"   %@", self.adTitles[itemIndex]];
    }
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.totalPageCount == 0) {
        return;
    }
    
    if (self.didSelectItemBlock) {
        self.didSelectItemBlock(indexPath.item % self.imageUrls.count);
    }
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (self.totalPageCount == 0) {
        return;
    }
    
    int itemIndex = (scrollView.contentOffset.x +
                     self.collectionView.DC_width * 0.5) / self.collectionView.DC_width;
    itemIndex = itemIndex % self.imageUrls.count;
    _pageControl.currentPage = itemIndex;
    
    // record
    self.previousPageIndex = itemIndex;
    
    CGFloat x = scrollView.contentOffset.x - self.collectionView.DC_width;
    NSUInteger index = fabs(x) / self.collectionView.DC_width;
    CGFloat fIndex = fabs(x) / self.collectionView.DC_width;
    
    if (self.didScrollBlock && fabs(fIndex - (CGFloat)index) <= 0.00001) {
        self.didScrollBlock(itemIndex);
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self pauseTimer];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    [self configTimer];
}

- (void)clearImagesCache {
    // 放在了非公开的扩展中，但是方法是存在的
    if ([[UIApplication sharedApplication] respondsToSelector:NSSelectorFromString(@"DC_clearDiskCaches")]) {
        ((void (*)(id, SEL))objc_msgSend)([UIApplication sharedApplication],
                                          NSSelectorFromString(@"DC_clearDiskCaches"));
    }
}

- (unsigned long long)imagesCacheSize {
    NSString *directoryPath = [NSHomeDirectory() stringByAppendingString:@"/Documents/DCLoopScollViewImages"];
    BOOL isDir = NO;
    unsigned long long total = 0;
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:directoryPath isDirectory:&isDir]) {
        if (isDir) {
            NSError *error = nil;
            NSArray *array = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:directoryPath error:&error];
            
            if (error == nil) {
                for (NSString *subpath in array) {
                    NSString *path = [directoryPath stringByAppendingPathComponent:subpath];
                    NSDictionary *dict = [[NSFileManager defaultManager] attributesOfItemAtPath:path
                                                                                          error:&error];
                    if (!error) {
                        total += [dict[NSFileSize] unsignedIntegerValue];
                    }
                }
            }
        }
    }
    
    return total;
}


@end
