//
//  SINetworkCache.m
//  SINetworkManagerDemo
//
//  Created by Silence on 2017/3/9.
//  Copyright © 2017年 Silence. All rights reserved.
//

#import "SINetworkCache.h"
#import <YYCache/YYCache.h>

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
    if (!para)  return url ;
    
    NSData *stringData = [NSJSONSerialization dataWithJSONObject:para options:0 error:nil] ;
    NSString *paraString = [[NSString alloc]initWithData:stringData encoding:NSUTF8StringEncoding] ;
    
    // 拼接
    NSString *cacheKey = [NSString stringWithFormat:@"%@%@",url,paraString] ;
    
    return cacheKey ;
}

@end

