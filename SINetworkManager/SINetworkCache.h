//
//  SINetworkCache.h
//  SINetworkManagerDemo
//
//  Created by 杨晴贺 on 2017/3/9.
//  Copyright © 2017年 Silence. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^SIRequestCacheBlock)(id responseCache) ; ///>  缓存Block


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
