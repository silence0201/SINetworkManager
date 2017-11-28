//
//  SINetworkCache.h
//  SINetworkManagerDemo
//
//  Created by Silence on 2017/3/9.
//  Copyright © 2017年 Silence. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef BOOL(^SIRequestCacheBlock)(id responseCache) ;///>  缓存Block,返回值表示是否有效,若为NO重新进行请求

/** 缓存 */
@interface SINetworkCache : NSObject

/// 设置缓存
+ (void)setCache:(id)data URL:(NSString *)url parameters:(NSDictionary *)parameters ;

/// 获取缓存
+ (id)cacheForURL:(NSString *)url parameters:(NSDictionary *)parameters ;
/// 获取缓存带有回调
+ (id)cacheForURL:(NSString *)url parameters:(NSDictionary *)parameters withBlock:(SIRequestCacheBlock)block ;

/// 获取缓存的大小
+ (NSInteger)getAllCacheSize ;
/// 删除所有的缓存
+ (void)removeAllCache ;

@end
