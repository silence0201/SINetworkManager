//
//  SINetworkManager.h
//  SINetworkManagerDemo
//
//  Created by 杨晴贺 on 2017/3/8.
//  Copyright © 2017年 Silence. All rights reserved.
//

#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN

///网络状态变化时发出通知
FOUNDATION_EXPORT NSString *const SINetworkStatusDidChangeNotification ;

typedef NS_ENUM(NSInteger,SINetworkStatusType) {
    SINetworkStatusUnknow = 0,          ///< 未知网络
    SINetworkStatusNotReachable,        ///< 无网络
    SINetworkStatusReachableViaWWAN,    ///< 蜂窝网络
    SINetworkStatusReachableViaWiFi,    ///< wifi
};


typedef NS_ENUM(NSInteger,SIRequestSerializerType){
    SIRequestSerializerHTTP = 0, ///< 请求的数据格式为二进制数据
    SIRequestSerializerJSON     ///< 请求数据为JSON格式
};

typedef NS_ENUM(NSInteger,SIResponseSerializerType){
    SIResponseSerializerHTTP = 0, ///< 返回的数据格式为二进制数据
    SIResponseSerializerJSON,     ///< 返回数据为JSON格式
    SIResponseSerializerXML       ///< 返回的数据为XML
};



typedef void(^SIRequestCacheBlock)(id responseCache) ; ///>  缓存Block
typedef void(^SINetworkStatusBlock)(SINetworkStatusType status) ; ///> 网络状态发生改变

@interface SINetworkCache : NSObject

+ (void)setCache:(id)data URL:(NSString *)url parameters:(NSDictionary *)parameters ;

+ (id)cacheForURL:(NSString *)url parameters:(NSDictionary *)parameters ;
+ (id)cacheForURL:(NSString *)url parameters:(NSDictionary *)parameters withBlock:(SIRequestCacheBlock)block ;

+ (NSInteger)getAllCacheSize ;

+ (void)removeAllCache ;

@end

@interface SINetworkConfig : NSObject

/// 根地址
@property (nonatomic,copy) NSString *baseURL ;
/// 公共参数
@property (nonatomic,copy) NSDictionary *commonParas ;
/// 超时时间,默认为30s
@property (nonatomic,assign) NSTimeInterval timeoutInterval ;

/// 请求数据类型,默认是二进制类型
@property (nonatomic,assign) SIRequestSerializerType requestSerializerType ;
/// 返回数据类型,默认是二进制
@property (nonatomic,assign) SIResponseSerializerType responseSerializerType ;

/// 是否显示转动的菊花
@property (nonatomic,assign) BOOL networkActivityIndicatorEnabled ;
/// 是否使用Cookie
@property (nonatomic,assign) BOOL cookieEnabled ;
/// 是否打开调试信息
@property (nonatomic,assign) BOOL debugLogEnable ;

/// 请求头信息
@property (nonatomic,readonly,copy) NSDictionary *allHTTPHeaderFields ;
/// 设置请求头信息
- (void)setValue:(NSString *)value forHTTPHeaderField:(nonnull NSString *)field ;

/// 默认设置
+ (instancetype)defaultConfig ;

@end

@interface SINetworkManager : NSObject

#pragma mark --- init
- (instancetype)initWithConfig:(SINetworkConfig *)config ;
+ (instancetype)defaultManager ;

#pragma mark --- 网络状态
/// 网络是否可用
+ (BOOL)isNetwork ;
/// 是不是蜂窝煤网络
+ (BOOL)isWWANNetwork ;
/// 是否是WiFi网络
+ (BOOL)isWiFiNetwork ;
/// 网络状态
+ (SINetworkStatusType)networkStatusType ;
/// 网络状态发生改变,可能被多次调用
+ (void)networkStatusChageWithBlock:(SINetworkStatusBlock)block ;



@end

NS_ASSUME_NONNULL_END
