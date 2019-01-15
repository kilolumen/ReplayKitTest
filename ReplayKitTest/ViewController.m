//
//  ViewController.m
//  ReplayKitTest
//
//  Created by Li,Dongjie on 2018/12/26.
//  Copyright © 2018 Li,Dongjie. All rights reserved.
//

#import "ViewController.h"
#import <ReplayKit/ReplayKit.h>
#import <VideoToolbox/VideoToolbox.h>
#import <WebKit/WebKit.h>
#import <SDWebImage/SDImageCache.h>

@interface ViewController () <UIScrollViewDelegate, UIWebViewDelegate, WKNavigationDelegate>

@property (nonatomic, strong) NSString *test;
@property (nonatomic, strong) UIView *footer;
@property (nonatomic, strong) UIWebView *webView;

@end

@implementation ViewController
@synthesize test = _test;

- (IBAction)clearCache:(id)sender {
    [[SDImageCache sharedImageCache] clearDiskOnCompletion:^{
        NSLog(@"clear finish");
    }];
}

- (void)dealloc {
    [self.webView.scrollView removeObserver:self forKeyPath:@"contentSize" context:nil];
    
    // 尝试释放资源，不一定管用
    [self.webView loadHTMLString:@"" baseURL:nil];
    [self.webView stopLoading];
    self.webView.delegate = nil;
    [self.webView removeFromSuperview];
    _webView = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    /*
    NSSet *websiteTypes = [NSSet setWithArray:@[
                                                WKWebsiteDataTypeDiskCache,
                                                WKWebsiteDataTypeMemoryCache]];
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:0];
    [[WKWebsiteDataStore defaultDataStore] removeDataOfTypes:websiteTypes
                                               modifiedSince:date
                                           completionHandler:^{
                                           }];
    WKWebView *webView = [[WKWebView alloc] initWithFrame:self.view.bounds];
    webView.navigationDelegate = self;
     */
    UIWebView *webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
    webView.backgroundColor = [UIColor whiteColor];
    webView.delegate = self;
    webView.scrollView.delegate = self;
    [self.view addSubview:webView];
    self.webView = webView;
    
    NSString *url1 = @"https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1548071237&di=9c731ac04ceff2fc115e3034a844bbe5&imgtype=jpg&er=1&src=http%3A%2F%2Fimg.ph.126.net%2F1BxarG_W2_0cZr3ua9pf4Q%3D%3D%2F3202340810037482562.jpg";
    NSString *url2 = @"https://timgsa.baidu.com/timg?image&quality=80&size=b999_1000&sec=1548071138&di=ab74cb46a31ce2548155a077851e32da&imgtype=jpg&er=1&src=http%3A%2F%2F5b0988e595225.cdn.sohucs.com%2Fimages%2F20171108%2F2cfddb197e1d494183e441bca7a5a697.jpeg";
    NSString *url3 = @"https://ss3.bdstatic.com/70cFv8Sh_Q1YnxGkpoWK1HF6hhy/it/u=1200224163,1889507562&fm=26&gp=0.jpg";
    
    NSString *htmlString = [NSString stringWithFormat:@"<html>"
                            "<head>"
                            "<style type=\"text/css\">"
                            "img{"
                            "border: 0px;"
                            "top: 0;"
                            "bottom: 0;"
                            "left: 0;"
                            "right: 0;"
                            "vertical-align: bottom;"
                            "margin: 0px auto;"
                            "max-width: 100%%;"
                            "height: auto;"
                            "display: block;"
                            "}"
                            "</style>"
                            "</head>"
                            "<body>"
                            "<img src='%@' />"
                            "<img src='%@' />"
                            "<img src='%@' />"
                            "</body></html>", url1, url2, url3];
    
//     style=\"border: 0px; vertical-align: bottom; display: block; margin: 0px auto; max-width: 100%; height: auto;\"
    [webView loadHTMLString:htmlString baseURL:nil];
    
    
    webView.scrollView.contentInset = UIEdgeInsetsMake(0, 0, 200, 0);
    
    _footer = [[UIView alloc] initWithFrame:CGRectMake(0, webView.scrollView.contentSize.height, 200, 100)];
    _footer.backgroundColor = [UIColor redColor];
    [webView.scrollView addSubview:_footer];


    [webView.scrollView addObserver:self forKeyPath:@"contentSize" options:NSKeyValueObservingOptionNew context:nil];
    
    /*
    NSDictionary *dict = [NSDictionary dictionary];
//    NSLog(@"%@", dict[AVCaptureSessionInterruptionReasonKey]);
    NSInteger reason = AVCaptureSessionInterruptionReasonAudioDeviceInUseByAnotherClient;
        switch (reason)
        {
            case AVCaptureSessionInterruptionReasonAudioDeviceInUseByAnotherClient:
                break;
            case AVCaptureSessionInterruptionReasonVideoDeviceInUseByAnotherClient:
                break;
            case AVCaptureSessionInterruptionReasonVideoDeviceNotAvailableInBackground:
                break;
            case AVCaptureSessionInterruptionReasonVideoDeviceNotAvailableWithMultipleForegroundApps:
                break;
            default:
                NSLog(@"------------");
                break;
        }
*/
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"contentSize"]) {
        CGRect frame = _footer.frame;
        frame.origin.y = self.webView.scrollView.contentSize.height;
        _footer.frame = frame;
//
//        self.webViewHeight = [[self.showWebView stringByEvaluatingJavaScriptFromString:@"document.body.scrollHeight"] floatValue];//通过webview的contentSize获取内容高度//
//        self.webViewHeight = [self.showWebView.scrollView contentSize].height;
//        CGRect newFrame = self.showWebView.frame;
//        newFrame.size.height  = self.webViewHeight;
//        NSLog(@"-document.body.scrollHeight-----%f",self.webViewHeight);NSLog(@"-contentSize-----%f",self.webViewHeight);
//        [self createBtn];
//        self.showWebView.frame = CGRectMake(0, 0, 375, self.webViewHeight);
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGRect frame = _footer.frame;
    frame.origin.y = scrollView.contentSize.height;
    _footer.frame = frame;
}


- (void)webViewDidFinishLoad:(UIWebView *)webView {
    CGRect frame = _footer.frame;
    frame.origin.y = webView.scrollView.contentSize.height;
    _footer.frame = frame;
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)startRecord {
    [[RPScreenRecorder sharedRecorder] startCaptureWithHandler:^(CMSampleBufferRef  _Nonnull sampleBuffer, RPSampleBufferType bufferType, NSError * _Nullable error) {
        if (CMSampleBufferDataIsReady(sampleBuffer) && bufferType == RPSampleBufferTypeVideo) {
            NSLog(@"Recording started successfully.");
            //save 屏幕数据
        }
    } completionHandler:^(NSError * _Nullable error) {
        NSLog(@"%@");
    }];
}

-(void)stopRecord {
    
    if (@available(iOS 11.0, *)) {
        [[RPScreenRecorder sharedRecorder] stopCaptureWithHandler:^(NSError * _Nullable error) {
            NSLog(@"stopCaptureWithHandler error %@", error);
        }];
    } else {
        NSLog(@"CDPReplay:system < 11.0");
    }
}

// CMSampleBufferRef转彩色UIImage，简单有效
- (UIImage *) imageFromSampleBuffer9:(CMSampleBufferRef) sampleBuffer
{
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CGImageRef image = NULL;
    OSStatus createdImage = VTCreateCGImageFromCVPixelBuffer(imageBuffer, NULL, &image);
    UIImage * image1 = nil;
    if (createdImage == noErr) {
        image1 = [UIImage imageWithCGImage:image];
    }
    CGImageRelease(image);
    
    return image1;
}

// CMSampleBufferRef转彩色UIImage
#define clamp(a) (a>255?255:(a<0?0:a))
- (UIImage *)imageFromSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(imageBuffer,0);
    
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    uint8_t *yBuffer = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0);
    size_t yPitch = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer, 0);
    uint8_t *cbCrBuffer = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 1);
    size_t cbCrPitch = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer, 1);
    
    int bytesPerPixel = 4;
    uint8_t *rgbBuffer = malloc(width * height * bytesPerPixel);
    
    for(int y = 0; y < height; y++) {
        uint8_t *rgbBufferLine = &rgbBuffer[y * width * bytesPerPixel];
        uint8_t *yBufferLine = &yBuffer[y * yPitch];
        uint8_t *cbCrBufferLine = &cbCrBuffer[(y >> 1) * cbCrPitch];
        
        for(int x = 0; x < width; x++) {
            int16_t y = yBufferLine[x];
            int16_t cb = cbCrBufferLine[x & ~1] - 128;
            int16_t cr = cbCrBufferLine[x | 1] - 128;
            
            uint8_t *rgbOutput = &rgbBufferLine[x*bytesPerPixel];
            
            int16_t r = (int16_t)roundf( y + cr *  1.4 );
            int16_t g = (int16_t)roundf( y + cb * -0.343 + cr * -0.711 );
            int16_t b = (int16_t)roundf( y + cb *  1.765);
            
            rgbOutput[0] = 0xff;
            rgbOutput[1] = clamp(b);
            rgbOutput[2] = clamp(g);
            rgbOutput[3] = clamp(r);
        }
    }
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(rgbBuffer, width, height, 8, width * bytesPerPixel, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaNoneSkipLast);
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    UIImage *image = [UIImage imageWithCGImage:quartzImage];
    
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    CGImageRelease(quartzImage);
    free(rgbBuffer);
    
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    
    return image;
}

// CMSampleBufferRef转黑白UIImage
-(UIImage *)imageFromSampleBuffer2:(CMSampleBufferRef) sampleBuffer {
    
    // 为媒体数据设置一个CMSampleBuffer的Core Video图像缓存对象
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    if (imageBuffer == nil) {
        return nil;
    }
    
    // 锁定pixel buffer的基地址
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    void *baseAddress = CVPixelBufferGetBaseAddressOfPlane(imageBuffer,0);
    //    CVPixelBufferGetBaseAddress(imageBuffer);
    
    size_t bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer,0);
    //    CVPixelBufferGetBytesPerRow(imageBuffer);
    // 得到pixel buffer的宽和高
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    if (width == 0 || height == 0) {return nil;}
    
    // 创建一个依赖于设备的RGB颜色空间
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
    
    // 用抽样缓存的数据创建一个位图格式的图形上下文（graphics context）对象
    CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8,
                                                 bytesPerRow, colorSpace,kCGImageAlphaNone);
    
    
    //    CGAffineTransform transform = CGAffineTransformIdentity;
    //    CGContextConcatCTM(context, transform);
    
    // 根据这个位图context中的像素数据创建一个Quartz image对象
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    
    // 裁剪 图片
    //    struct CGImage *cgImage = CGImageCreateWithImageInRect(quartzImage, CGRectMake(0, 0, height, height));
    
    // 解锁pixel buffer
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    
    // 释放context和颜色空间
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    // 用Quartz image创建一个UIImage对象image
    UIImage *image = [UIImage imageWithCGImage:quartzImage];
    
    // 释放Quartz image对象
    //    CGImageRelease(cgImage);
    CGImageRelease(quartzImage);
    
    return (image);
    
}


@end
