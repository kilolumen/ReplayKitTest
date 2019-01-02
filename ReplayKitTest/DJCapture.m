//
//  DJCapture.m
//  ReplayKitTest
//
//  Created by Li,Dongjie on 2019/1/2.
//  Copyright © 2019 Li,Dongjie. All rights reserved.
//

#import "DJCapture.h"
#import <UIKit/UIKit.h>
#import <OpenGLES/ES1/glext.h>

//录制cocos2d-x游戏画面（iOS）
// https://www.zaczh.me/jekyll/update/2017/04/29/cocos2d-x-texture-streaming

// Unity3D的视频录制（iOS + Metal）
// http://www.acros.me/unity3d/unity3d%E7%9A%84%E8%A7%86%E9%A2%91%E5%BD%95%E5%88%B6%EF%BC%88ios-metal%EF%BC%89/

// ShareREC for iOS录屏原理解析
// https://blog.csdn.net/Mob_com/article/details/79033424
@implementation DJCapture {
    GLuint _colorRenderbuffer;
}

// IMPORTANT: Call this method after you draw and before -presentRenderbuffer:.
- (UIImage*)snapshot:(UIView*)eaglview
{
    GLint backingWidth, backingHeight;
    
    // Bind the color renderbuffer used to render the OpenGL ES view
    // If your application only creates a single color renderbuffer which is already bound at this point,
    // this call is redundant, but it is needed if you're dealing with multiple renderbuffers.
    // Note, replace "_colorRenderbuffer" with the actual name of the renderbuffer object defined in your class.
    glBindRenderbufferOES(GL_RENDERBUFFER_OES, _colorRenderbuffer);
    
    // Get the size of the backing CAEAGLLayer
    glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_WIDTH_OES, &backingWidth);
    glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_HEIGHT_OES, &backingHeight);
    
    NSInteger x = 0, y = 0, width = backingWidth, height = backingHeight;
    NSInteger dataLength = width * height * 4;
    GLubyte *data = (GLubyte*)malloc(dataLength * sizeof(GLubyte));
    
    // Read pixel data from the framebuffer
    glPixelStorei(GL_PACK_ALIGNMENT, 4);
    glReadPixels(x, y, width, height, GL_RGBA, GL_UNSIGNED_BYTE, data);
    
    // Create a CGImage with the pixel data
    // If your OpenGL ES content is opaque, use kCGImageAlphaNoneSkipLast to ignore the alpha channel
    // otherwise, use kCGImageAlphaPremultipliedLast
    CGDataProviderRef ref = CGDataProviderCreateWithData(NULL, data, dataLength, NULL);
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    CGImageRef iref = CGImageCreate(width, height, 8, 32, width * 4, colorspace, kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast,
                                    ref, NULL, true, kCGRenderingIntentDefault);
    
    // OpenGL ES measures data in PIXELS
    // Create a graphics context with the target size measured in POINTS
    NSInteger widthInPoints, heightInPoints;
    if (NULL != UIGraphicsBeginImageContextWithOptions) {
        // On iOS 4 and later, use UIGraphicsBeginImageContextWithOptions to take the scale into consideration
        // Set the scale parameter to your OpenGL ES view's contentScaleFactor
        // so that you get a high-resolution snapshot when its value is greater than 1.0
        CGFloat scale = eaglview.contentScaleFactor;
        widthInPoints = width / scale;
        heightInPoints = height / scale;
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(widthInPoints, heightInPoints), NO, scale);
    }
    else {
        // On iOS prior to 4, fall back to use UIGraphicsBeginImageContext
        widthInPoints = width;
        heightInPoints = height;
        UIGraphicsBeginImageContext(CGSizeMake(widthInPoints, heightInPoints));
    }
    
    CGContextRef cgcontext = UIGraphicsGetCurrentContext();
    
    // UIKit coordinate system is upside down to GL/Quartz coordinate system
    // Flip the CGImage by rendering it to the flipped bitmap context
    // The size of the destination area is measured in POINTS
    CGContextSetBlendMode(cgcontext, kCGBlendModeCopy);
    CGContextDrawImage(cgcontext, CGRectMake(0.0, 0.0, widthInPoints, heightInPoints), iref);
    
    // Retrieve the UIImage from the current context
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    // Clean up
    free(data);
    CFRelease(ref);
    CFRelease(colorspace);
    CGImageRelease(iref);
    
    return image;
}

-(UIImage *) glToUIImage {
    NSInteger myDataLength = 1024 * 768 * 4;  //1024-width，768-height
    
    // allocate array and read pixels into it.
    GLubyte *buffer = (GLubyte *) malloc(myDataLength);
    glReadPixels(0, 0, 1024, 768, GL_RGBA, GL_UNSIGNED_BYTE, buffer);
    
    // gl renders "upside down" so swap top to bottom into new array.
    // there's gotta be a better way, but this works.
    GLubyte *buffer2 = (GLubyte *) malloc(myDataLength);
    for(int y = 0; y <768; y++)
    {
        for(int x = 0; x <1024 * 4; x++)
        {
            buffer2[(767 - y) * 1024 * 4 + x] = buffer[y * 4 * 1024 + x];
        }
    }
    
    // make data provider with data.
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, buffer2, myDataLength, NULL);
    
    // prep the ingredients
    int bitsPerComponent = 8;
    int bitsPerPixel = 32;
    int bytesPerRow = 4 * 1024;
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
    
    // make the cgimage
    CGImageRef imageRef = CGImageCreate(1024, 768, bitsPerComponent, bitsPerPixel, bytesPerRow, colorSpaceRef, bitmapInfo, provider, NULL, NO, renderingIntent);
    
    // then make the uiimage from that
    UIImage *myImage = [UIImage imageWithCGImage:imageRef];
    return myImage;
}

//合并图片
-(UIImage *)mergerImage:(UIImage *)firstImage secodImage:(UIImage *)secondImage{
    
    CGSize imageSize = CGSizeMake(620, 380);
    UIGraphicsBeginImageContext(imageSize);
    
    [firstImage drawInRect:CGRectMake(0, 0, firstImage.size.width, firstImage.size.height)];
    [secondImage drawInRect:CGRectMake(310 - 40, 190 - 60, secondImage.size.width, secondImage.size.height)];
    
    UIImage *resultImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return resultImage;
}

- (UIImage*)screenshot
{
    // Create a graphics context with the target size
    // On iOS 4 and later, use UIGraphicsBeginImageContextWithOptions to take the scale into consideration
    // On iOS prior to 4, fall back to use UIGraphicsBeginImageContext
    CGSize imageSize = [[UIScreen mainScreen] bounds].size;
    if (NULL != UIGraphicsBeginImageContextWithOptions)
        UIGraphicsBeginImageContextWithOptions(imageSize, NO, 0);
    else
        UIGraphicsBeginImageContext(imageSize);
    
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    
    // Iterate over every window from back to front
    for (UIWindow *window in [[UIApplication sharedApplication] windows])
    {
        if (![window respondsToSelector:@selector(screen)] || [window screen] == [UIScreen mainScreen])
        {
            // -renderInContext: renders in the coordinate space of the layer,
            // so we must first apply the layer's geometry to the graphics context
            CGContextSaveGState(context);
            // Center the context around the window's anchor point
            CGContextTranslateCTM(context, [window center].x, [window center].y);
            // Apply the window's transform about the anchor point
            CGContextConcatCTM(context, [window transform]);
            // Offset by the portion of the bounds left of and above the anchor point
            CGContextTranslateCTM(context,
                                  -[window bounds].size.width * [[window layer] anchorPoint].x,
                                  -[window bounds].size.height * [[window layer] anchorPoint].y);
            
            
            // Render the layer hierarchy to the current context
            [[window layer] renderInContext:context];
            
            
            // Restore the context
            CGContextRestoreGState(context);
        }
    }
    
    
    // Retrieve the screenshot image
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    
    UIGraphicsEndImageContext();
    
    
    return image;
}


- (void)renderCachedTextureScale {
    CHECK_GL_ERROR;
    
    if (colorRenderbuffer_ == 0) {
        NSLog(@"offscreen frame buffer not prepared");
        return;
    }
    
    CGSize resolution = [[QGRTMPClient sharedClient] videResolution];
    CGFloat videoWidth = resolution.width;
    CGFloat videoHeight = resolution.height;
    
    glUseProgram(self.textureProgramScale);
    glBindFramebuffer(GL_FRAMEBUFFER, self.textureFramebufferScale);
    glBindRenderbuffer(GL_RENDERBUFFER, self.textureRenderbufferScale);
    CHECK_GL_ERROR;
    
    glViewport(0, 0, videoWidth, videoHeight);
    
    glBindTexture(GL_TEXTURE_2D, colorRenderbuffer_);
    CHECK_GL_ERROR;
    
    glBindBuffer(GL_ARRAY_BUFFER, self.textureVBScale);
    CHECK_GL_ERROR;
    
    glVertexAttribPointer(self.textureCoordsSlotScale,
                          2,
                          GL_FLOAT,
                          GL_FALSE,
                          sizeof(VertexBuffer),
                          (void *)offsetof(VertexBuffer, Coords));
    glEnableVertexAttribArray(self.textureCoordsSlotScale);
    CHECK_GL_ERROR;
    
    glVertexAttribPointer(self.positionSlotScale,
                          2,
                          GL_FLOAT,
                          GL_FALSE,
                          sizeof(VertexBuffer),
                          (void *)offsetof(VertexBuffer, Position));
    glEnableVertexAttribArray(self.positionSlotScale);
    CHECK_GL_ERROR;
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    CHECK_GL_ERROR;
    
    glBindTexture(GL_TEXTURE_2D, 0); // 使用完之后解绑
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glDisableVertexAttribArray(self.textureCoordsSlotScale);
    glDisableVertexAttribArray(self.positionSlotScale);
    
    CHECK_GL_ERROR;
}

//用于缩放操作的program初始化:
- (void)prepareTextureProgramScale {
    if (self.textureProgramScale > 0) {
        return;
    }
    
    // 1
    GLuint fragmentShader = [self compileShader: @"\
                             precision mediump float;\
                             uniform sampler2D Texture;\
                             varying vec2 TextureCoordsOut;\
                             void main(void)\
                             {\
                             vec4 mask = texture2D(Texture, TextureCoordsOut);\
                             gl_FragColor = vec4(mask.rgb, 1.0);\
                             }"
                                       withType:GL_FRAGMENT_SHADER];
    
    GLuint vertexShader = [self compileShader:@"\
                           attribute vec2 Position;\
                           attribute vec2 TextureCoords;\
                           varying vec2 TextureCoordsOut;\
                           void main(void)\
                           {\
                           gl_Position = vec4(Position, 0, 1);\
                           TextureCoordsOut = vec2(TextureCoords.x, 1.0 - TextureCoords.y);\
                           }"
                                     withType:GL_VERTEX_SHADER];
    
    // 2
    GLuint programHandle = glCreateProgram();
    glAttachShader(programHandle, fragmentShader);
    glAttachShader(programHandle, vertexShader);
    glLinkProgram(programHandle);
    
    // 3
    GLint linkSuccess;
    glGetProgramiv(programHandle, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetProgramInfoLog(programHandle, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"[Error]%@", messageString);
    }
    CHECK_GL_ERROR;
    
    // 4
    glUseProgram(programHandle);
    
    // 5
    self.positionSlotScale = glGetAttribLocation(programHandle, "Position");
    self.textureSlotScale = glGetUniformLocation(programHandle, "Texture");
    self.textureCoordsSlotScale = glGetAttribLocation(programHandle, "TextureCoords");
    
    glEnableVertexAttribArray(self.positionSlot);
    CHECK_GL_ERROR;
    self.textureProgramScale = programHandle;
    
    GLuint framebuffer = 0;
    glGenFramebuffers(1, &framebuffer);
    NSAssert(framebuffer, @"Can't create texture frame buffer");
    self.textureFramebufferScale = framebuffer;
    
    glBindFramebuffer(GL_FRAMEBUFFER, self.textureFramebufferScale);
    //create scaled texture cache and store it
    CVPixelBufferRef buf = 0;
    self.textureRenderbufferScale = [self createTextureCacheStore:&buf];
    self.renderTargetPixelBuffer = buf;
    CHECK_GL_ERROR;
    
    glBindRenderbuffer(GL_RENDERBUFFER, self.textureRenderbufferScale);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, self.textureRenderbufferScale, 0);
    CHECK_GL_ERROR;
    
    CGSize resolution = [[QGRTMPClient sharedClient] videResolution];
    int cacheTextureWidth = resolution.width;
    int cacheTextureHeight = resolution.height;
    
    NSLog(@"cocos2d: scaled surface size: %dx%d", (int)cacheTextureWidth, (int)cacheTextureHeight);
    
    CHECK_GL_ERROR;
    if(self.textureDepthbufferScale == 0) {
        GLuint textureDepthbuffer = 0;
        glGenRenderbuffers(1, &textureDepthbuffer);
        self.textureDepthbufferScale = textureDepthbuffer;
        NSLog(@"[Error]Can't create texture depth buffer");
    }
    
    glBindRenderbuffer(GL_RENDERBUFFER, self.textureDepthbufferScale);
    CHECK_GL_ERROR;
    
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, cacheTextureWidth, cacheTextureHeight);
    CHECK_GL_ERROR;
    
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, self.textureDepthbufferScale);
    CHECK_GL_ERROR;
    
    [self setupVBScale];
    CHECK_GL_ERROR;
    
    GLenum error;
    if((error = glCheckFramebufferStatus(GL_FRAMEBUFFER)) != GL_FRAMEBUFFER_COMPLETE) {
        NSLog(@"[Error]Failed to make complete framebuffer object 0x%X", error);
    }
}
@end
