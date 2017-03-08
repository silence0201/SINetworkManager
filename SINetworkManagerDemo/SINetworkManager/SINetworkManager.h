//
//  SINetworkManager.h
//  SINetworkManagerDemo
//
//  Created by 杨晴贺 on 2017/3/8.
//  Copyright © 2017年 Silence. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SINetworkCache : NSObject

+ (void)setCache:(id)data URL:(NSString *)url parameters:(NSDictionary *)parameters ;

+ (id)cacheForURL:(NSString *)url parameters:(NSDictionary *)parameters ;

+ (NSInteger)getAllCacheSize ;

+ (void)removeAllCache ;

@end

@interface SINetworkManager : NSObject

@end
