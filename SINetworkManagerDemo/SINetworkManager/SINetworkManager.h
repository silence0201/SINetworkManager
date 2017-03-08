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
FOUNDATION_EXPORT NSString *const SINetworkingReachabilityNotificationStatusItem ;

typedef NS_ENUM(NSInteger,SINetworkStatusType) {
    SINetworkStatusUnknow = -1,          ///< 未知网络
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
typedef void(^SIRequestSuccessBlock)(NSURLSessionDataTask *task, NSDictionary *responseObject); ///> 请求成功的block
typedef void(^SIRequestFailureBlock)(NSURLSessionDataTask *task, NSError *error); ///> 请求失败的block
typedef void(^SIRequestProgressBlock)(NSProgress *progress) ; ///> 进度Block
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

#pragma mark --- 重置AFHTTPSessionManager相关属性
/// 设置config
+ (void)setConfig:(SINetworkConfig *)config ;
+ (SINetworkConfig *)sharedConfig;

/// 设置请求参数格式
+ (void)setRequestSerializer:(SIRequestSerializerType)requestSerializer ;
/// 设置相应数据格式
+ (void)setResponseSerializer:(SIResponseSerializerType)responseSerializer ;

/// 设置请求超时时间,默认30s
+ (void)setRequestTimeoutInterval:(NSTimeInterval)time ;

/// 设置请求头
+ (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field ;

/// 设置是否打开网络状态菊花
+ (void)openNetworkActivityIndicator:(BOOL)open ;

/**
 配置自建证书的Https请求, 参考链接: http://blog.csdn.net/syg90178aw/article/details/52839103

 @param cerPath 自建Https证书的路径
 @param validatesDomainName 是否需要验证域名，默认为YES. 如果证书的域名与请求的域名不一致，需设置为NO; 即服务器使用其他可信任机构颁发
 的证书，也可以建立连接，这个非常危险, 建议打开.validatesDomainName=NO, 主要用于这种情况:客户端请求的是子域名, 而证书上的是另外
 一个域名。因为SSL证书上的域名是独立的,假如证书上注册的域名是www.google.com, 那么mail.google.com是无法验证通过的.
 */
+ (void)setSecurityPolicyWithCerPath:(NSString *)cerPath validatesDomainName:(BOOL)validatesDomainName;

#pragma mark --- 请求数据

+ (NSURLSessionTask *)GET:(NSString *)url
               parameters:(NSDictionary *)parameters
                 succeess:(SIRequestSuccessBlock)success
                  failure:(SIRequestFailureBlock)failure;

+ (NSURLSessionTask *)GET:(NSString *)url
               parameters:(NSDictionary *)parameters
                 progress:(SIRequestProgressBlock)progress
            cacheResponse:(SIRequestCacheBlock)cacheResponse
                 succeess:(SIRequestSuccessBlock)success
                  failure:(SIRequestFailureBlock)failure;

+ (NSURLSessionTask *)POST:(NSString *)url
                parameters:(NSDictionary *)parameters
                   success:(SIRequestSuccessBlock)success
                   failure:(SIRequestFailureBlock)failure;

+ (NSURLSessionTask *)POST:(NSString *)url
                parameters:(NSDictionary *)parameters
                  progress:(SIRequestProgressBlock)progress
             cacheResponse:(SIRequestCacheBlock)cacheResponse
                   success:(SIRequestSuccessBlock)success
                   failure:(SIRequestFailureBlock)failure;

+ (NSURLSessionTask *)uploadFileWithURL:(NSString *)url
                             parameters:(NSDictionary *)parameters
                                   name:(NSString *)name
                               filePath:(NSString *)path
                               progress:(SIRequestProgressBlock)progress
                                success:(SIRequestSuccessBlock)success
                                failure:(SIRequestFailureBlock)failure;

@end

NS_ASSUME_NONNULL_END
