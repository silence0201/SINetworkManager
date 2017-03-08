//
//  SINetworkManager.m
//  SINetworkManagerDemo
//
//  Created by 杨晴贺 on 2017/3/8.
//  Copyright © 2017年 Silence. All rights reserved.
//

#import "SINetworkManager.h"
#import <YYCache/YYCache.h>


#pragma mark --- SINetworkCache
static NSString *const NetworkCacheName = @"SINetworkCache" ;
static YYCache *_networkCache ;
@implementation SINetworkCache

+ (void)initialize{
    _networkCache = [YYCache cacheWithName:NetworkCacheName] ;
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

#pragma mark ---- SINetworkConfig
@implementation SINetworkConfig{
    NSMutableDictionary *_httpHeaderDic ;
}

+ (instancetype)defaultConfig{
    static SINetworkConfig *config = nil ;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        config = [[self alloc]init] ;
    });
    return config ;
}

- (instancetype)init{
    if (self = [super init]) {
        _httpHeaderDic = [NSMutableDictionary dictionary] ;
    }
    return self ;
}

- (NSTimeInterval)timeoutInterval{
    return _timeoutInterval ? : 30 ;
}

- (BOOL)networkActivityIndicatorEnabled{
    return _networkActivityIndicatorEnabled ? : YES ;
}

- (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field{
    [_httpHeaderDic setValue:value forKey:field] ;
}

- (NSDictionary *)allHTTPHeaderFields{
    return _httpHeaderDic.copy ;
}

@end

#pragma mark ---- SINetworkManager
@implementation SINetworkManager
@end



