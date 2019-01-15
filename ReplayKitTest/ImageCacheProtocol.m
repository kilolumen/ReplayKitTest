//
//  ImageCacheProtocol.m
//  ReplayKitTest
//
//  Created by Li,Dongjie on 2019/1/15.
//  Copyright © 2019 Li,Dongjie. All rights reserved.
//

#import "ImageCacheProtocol.h"
#import <SDWebImage/SDWebImageManager.h>
#import <SDWebImage/UIImage+MultiFormat.h>

static NSString *const hasCacheKey = @"CustomWebViewProtocolKey";

@interface ImageCacheProtocol ()
@property (nonatomic, strong) NSMutableData *responseData;
@property (nonatomic, strong) NSURLConnection *connection;
@end
@implementation ImageCacheProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    NSString *scheme = [[request URL] scheme];
    if ([scheme caseInsensitiveCompare:@"http"] == NSOrderedSame || [scheme caseInsensitiveCompare:@"https"] == NSOrderedSame) {
        
        NSString *extension = [[request URL] pathExtension];
        if ([extension caseInsensitiveCompare:@".png"] == NSOrderedSame ||
            [extension caseInsensitiveCompare:@".jpg"] == NSOrderedSame ||
            [extension caseInsensitiveCompare:@".gif"] == NSOrderedSame ||
            [extension caseInsensitiveCompare:@".jpeg"] == NSOrderedSame ||
            [extension caseInsensitiveCompare:@".webp"] == NSOrderedSame) {
            if (![NSURLProtocol propertyForKey:hasCacheKey inRequest:request]) {
                return YES;
            }
        }

        NSString *url = request.URL.absoluteString;
        if ([url hasSuffix:@".png"] ||
            [url hasSuffix:@".jpg"] ||
            [url hasSuffix:@".gif"] ||
            [url hasSuffix:@".jpeg"] ||
            [url hasSuffix:@".webp"]) {
            if (![NSURLProtocol propertyForKey:hasCacheKey inRequest:request]) {
                return YES;
            }
        }
        
    }
    return NO;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    return request;
}

- (void)startLoading {
    NSString *key = [[SDWebImageManager sharedManager] cacheKeyForURL:self.request.URL];
    NSData *data = [[SDImageCache sharedImageCache] diskImageDataForKey:key];
    if (data) {
        NSString *mimeType = @"image/jpeg";
        NSURLResponse *response = [[NSURLResponse alloc] initWithURL:self.request.URL
                                                            MIMEType:mimeType
                                               expectedContentLength:data.length
                                                    textEncodingName:nil];
        
        [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
        [self.client URLProtocol:self didLoadData:data];
        [self.client URLProtocolDidFinishLoading:self];
    } else {
        NSMutableURLRequest *mutableReqeust = [[self request] mutableCopy];
        [NSURLProtocol setProperty:@YES forKey:hasCacheKey inRequest:mutableReqeust];
        self.connection = [NSURLConnection connectionWithRequest:mutableReqeust delegate:self];
    }
}

- (void)stopLoading {
    [self.connection cancel];
}

#pragma mark- NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [self.client URLProtocol:self didFailWithError:error];
}

#pragma mark - NSURLConnectionDataDelegate
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    self.responseData = [[NSMutableData alloc] init];
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.responseData appendData:data];
    [self.client URLProtocol:self didLoadData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    
    UIImage *cacheImage = [UIImage sd_imageWithData:self.responseData];
    [[SDImageCache sharedImageCache] storeImage:cacheImage
                                      imageData:self.responseData
                                         forKey:[[SDWebImageManager sharedManager] cacheKeyForURL:self.request.URL]
                                         toDisk:YES
                                     completion:nil];
    
    [self.client URLProtocolDidFinishLoading:self];
}

@end
