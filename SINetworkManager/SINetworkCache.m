//
//  SINetworkCache.m
//  SINetworkManagerDemo
//
//  Created by Silence on 2017/3/9.
//  Copyright © 2017年 Silence. All rights reserved.
//

#import "SINetworkCache.h"
#import <YYCache/YYCache.h>
#import <CommonCrypto/CommonDigest.h>

static NSString *const NetworkCacheName = @"SINetworkCache" ;
static YYCache *_networkCache ;
@implementation SINetworkCache

+ (void)initialize{
    _networkCache = [YYCache cacheWithName:NetworkCacheName] ;
    _networkCache.memoryCache.costLimit = 10*1024*1024; // 内存最多占用10M
    _networkCache.diskCache.costLimit = 200*1024*1024; // 硬盘最多占用200M
}

+ (void)setCache:(id)data URL:(NSString *)url parameters:(NSDictionary *)parameters{
    NSString *cacheKey = [self _keyWithURL:url paramters:parameters] ;
    [_networkCache setObject:data forKey:cacheKey] ;
}

+ (id)cacheForURL:(NSString *)url parameters:(NSDictionary *)parameters{
    NSString *cacheKey = [self _keyWithURL:url paramters:parameters] ;
    return  [_networkCache objectForKey:cacheKey] ;
}

+ (id)cacheForURL:(NSString *)url parameters:(NSDictionary *)parameters withBlock:(SIRequestCacheBlock)block{
    NSString *cacheKey = [self _keyWithURL:url paramters:parameters] ;
    if(block){
        [_networkCache objectForKey:cacheKey withBlock:^(NSString * _Nonnull key, id<NSCoding>  _Nonnull object) {
            dispatch_async(dispatch_get_main_queue(), ^{
                block(object) ;
            }) ;
        }] ;
    }
    return  [_networkCache objectForKey:cacheKey] ;
}


+ (void)removeAllCache{
    [_networkCache.diskCache removeAllObjects] ;
}

+ (NSInteger)getAllCacheSize{
    return [_networkCache.diskCache totalCost] ;
}

#pragma mark --- 私有方法
+ (NSString *)_keyWithURL:(NSString *)url paramters:(NSDictionary *)para{
    NSString *key;
    if (!para) {
        key = url;
    }else {
        NSMutableString *paraString = [NSMutableString string];
        for (NSString *key in [para allKeys]){
            if ([paraString length]){
                [paraString appendString:@"&"];
            }
            [paraString appendFormat:@"%@=%@", key, [para objectForKey:key]];
        }
        // 拼接
        key = [NSString stringWithFormat:@"%@?%@",url,paraString] ;
    }
    
    // MD5 From SDWebImage
    const char *str = key.UTF8String;
    if (str == NULL) {
        str = "";
    }
    unsigned char r[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, (CC_LONG)strlen(str), r);
    NSURL *keyURL = [NSURL URLWithString:key];
    NSString *ext = keyURL ? keyURL.pathExtension : key.pathExtension;
    NSString *filename = [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%@",
                          r[0], r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9], r[10],
                          r[11], r[12], r[13], r[14], r[15], ext.length == 0 ? @"" : [NSString stringWithFormat:@".%@", ext]];
    return filename ;
}

@end

@implementation NSDictionary (URL)

- (NSString *)URLQueryString{
    NSMutableString *string = [NSMutableString stringWithString:@"?"];
    for (NSString *key in [self allKeys]){
        if ([string length]){
            [string appendString:@"&"];
        }
        [string appendFormat:@"%@=%@", key, [self objectForKey:key]];
    }
    return string;
}

@end

