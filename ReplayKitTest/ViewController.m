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

@interface ViewController ()

@property (nonatomic, strong) NSString *test;

@end

@implementation ViewController
@synthesize test = _test;

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"ddddddd");
    self->_test = @"dd";
    NSLog(@"%@", _test);
    self.test = @"dd";
    NSLog(@"%@", _test);
    
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
