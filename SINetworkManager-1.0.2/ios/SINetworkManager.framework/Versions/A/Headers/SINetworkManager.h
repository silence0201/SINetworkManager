//
//  SINetworkManager.h
//  SINetworkManagerDemo
//
//  Created by 杨晴贺 on 2017/3/8.
//  Copyright © 2017年 Silence. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SINetworkCache.h"
#import "SINetworkConfig.h"

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

typedef void(^SINetworkStatusBlock)(SINetworkStatusType status) ; ///> 网络状态发生改变
typedef void(^SIRequestSuccessBlock)(NSURLSessionTask *task, NSDictionary *responseObject); ///> 请求成功的block
typedef void(^SIRequestFailureBlock)(NSURLSessionTask *task, NSError *error); ///> 请求失败的block
typedef void(^SIRequestProgressBlock)(NSProgress *progress) ; ///> 进度Block

@interface SINetworkManager : NSObject

#pragma mark --- 网络状态
#pragma mark -
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
#pragma mark -
/// 设置config,如果需要设置新的BaseURL需要设置新的Config,会生成新的Manager对象,会取消当前队列的所有请求
+ (void)setConfig:(SINetworkConfig *)config ;
/// 可获取当前的Config,某些属性设置就可以生效,但是不推荐使用
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
 配置自建证书的Https请求, 参考链接: http://www.jianshu.com/p/97745be81d64

 @param cerPath 自建Https证书的路径
 @param validatesDomainName 是否需要验证域名，默认为YES. 如果证书的域名与请求的域名不一致，需设置为NO;
 */
+ (void)setSecurityPolicyWithCerPath:(NSString *)cerPath validatesDomainName:(BOOL)validatesDomainName;

#pragma mark --- 请求数据
#pragma mark -
/**
 不带缓存的GET请求,数据会自动转换为JSON,解析XML需要设置ResponseSerializer,如果转换失败,会以@{@"result":reponse}格式返回

 @param url 请求地址
 @param parameters 请求参数
 @param success 成功回调
 @param failure 失败回调
 @return 返回当前的task
 */
+ (NSURLSessionTask *)GET:(NSString *)url
               parameters:(nullable NSDictionary *)parameters
                 succeess:(nullable SIRequestSuccessBlock)success
                  failure:(nullable SIRequestFailureBlock)failure;

/**
 带缓存的GET请求,数据会自动转换为JSON,解析XML需要设置ResponseSerializer,如果转换失败,会以@{@"result":reponse}格式返回


 @param url 请求地址
 @param parameters 请求参数
 @param progress 进度回调
 @param cacheResponse 缓存回调
 @param success 成功回调
 @param failure 失败回调
 @return 返回当前task
 */
+ (NSURLSessionTask *)GET:(NSString *)url
               parameters:(nullable NSDictionary *)parameters
                 progress:(nullable SIRequestProgressBlock)progress
            cacheResponse:(nullable SIRequestCacheBlock)cacheResponse
                 succeess:(nullable SIRequestSuccessBlock)success
                  failure:(nullable SIRequestFailureBlock)failure;

/**
 不带缓存的GET请求,数据会自动转换为JSON,解析XML需要设置ResponseSerializer,如果转换失败,会以@{@"result":reponse}格式返回

 @param url 请求地址
 @param parameters 请求参数
 @param success 成功回调
 @param failure 失败回调
 @return 返回当前task
 */
+ (NSURLSessionTask *)POST:(NSString *)url
                parameters:(nullable NSDictionary *)parameters
                   success:(nullable SIRequestSuccessBlock)success
                   failure:(nullable SIRequestFailureBlock)failure;

/**
 不带缓存的GET请求,数据会自动转换为JSON,解析XML需要设置ResponseSerializer,如果转换失败,会以@{@"result":reponse}格式返回

 @param url 请求地址
 @param parameters 请求参数
 @param progress 进度回调
 @param cacheResponse 缓存回调
 @param success 成功回调
 @param failure 失败回调
 @return 返回当前task
 */
+ (NSURLSessionTask *)POST:(NSString *)url
                parameters:(nullable NSDictionary *)parameters
                  progress:(nullable SIRequestProgressBlock)progress
             cacheResponse:(nullable SIRequestCacheBlock)cacheResponse
                   success:(nullable SIRequestSuccessBlock)success
                   failure:(nullable SIRequestFailureBlock)failure;

/**
 上传文件

 @param url 上传地址
 @param parameters 上传参数
 @param name 对应服务器的name
 @param path 本地沙盒路径
 @param progress 进度回调
 @param success 成功回调
 @param failure 失败回调
 @return 返回当前的task
 */
+ (NSURLSessionTask *)uploadFileWithURL:(NSString *)url
                             parameters:(nullable NSDictionary *)parameters
                                   name:(NSString *)name
                               filePath:(NSString *)path
                               progress:(nullable SIRequestProgressBlock)progress
                                success:(nullable SIRequestSuccessBlock)success
                                failure:(nullable SIRequestFailureBlock)failure;

/**
 上传图片

 @param url 上传地址
 @param parameters 上传参数
 @param name 文件对应服务器的name
 @param size 需要压缩上传文件的大小,如果大于0则压缩
 @param images 图片数组
 @param fileNames 图片文件名数组,如果为空默认nil
 @param imageType 图片类型
 @param progress 进度回调
 @param success 成功回调
 @param failure 失败回调
 @return 返回当前的Task
 */
+ (NSURLSessionTask *)uploadImageWithURL:(NSString *)url
                              parameters:(nullable NSDictionary *)parameters
                                    name:(NSString *)name
                             maxFileSize:(double)size
                                  images:(NSArray *)images
                               fileNames:(NSArray *)fileNames
                               imageType:(NSString *)imageType
                                progress:(nullable SIRequestProgressBlock)progress
                                 success:(nullable SIRequestSuccessBlock)success
                                 failure:(nullable SIRequestFailureBlock)failure;


/**
 下载文件

 @param URL 请求地址
 @param fileDir 文件保存目录,默认为缓存目录下Download文件夹
 @param progress 进度回调
 @param success 成功回调
 @param failure 失败回调
 @return 返回当前Task
 */
+ (NSURLSessionTask *)downloadWithURL:(NSString *)URL
                              fileDir:(NSString *)fileDir
                             progress:(nullable SIRequestProgressBlock)progress
                              success:(nullable void(^)(NSString *filePath))success
                              failure:(nullable SIRequestFailureBlock)failure;

#pragma mark - Task cancel
#pragma mark -
/// 取消请求对应URL的请求，取消的请求不再回调数据
+ (void)cancelTaskWithURL:(NSString *)URL;
/// 取消所有请求,取消的请求不再回调数据
+ (void)cancelAllTask;

#pragma mark - cookie 设置
#pragma mark -

///获取当前请求服务端返回的cookie
+ (void)getCookie:(NSString *)url;

/// 给请求设置Cookie,需要在Config中设置cookieEnabled为YES才能使用
+ (void)setLocalCookieWithCookieName:(NSArray *)names
                              values:(NSArray *)values
                           originURL:(NSString *)url
                             expires:(NSTimeInterval)expires;
/// 删除cookie
+ (void)clearCookie;

@end

NS_ASSUME_NONNULL_END
