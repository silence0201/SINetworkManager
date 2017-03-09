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

@interface SINetworkConfig : NSObject

/// 根地址,默认为空,如果需要设置需要创建新的Config
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
/// 设置config,如果需要设置新的BaseURL需要设置新的Config
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


/**
 不带缓存的GET请求,数据会自动转换为JSON,解析XML需要设置ResponseSerializer,如果转换失败,会以@{@"result":reponse}格式返回

 @param url 请求地址
 @param parameters 请求参数
 @param success 成功回调
 @param failure 失败回调
 @return 返回当前的task
 */
+ (NSURLSessionTask *)GET:(NSString *)url
               parameters:(NSDictionary *)parameters
                 succeess:(SIRequestSuccessBlock)success
                  failure:(SIRequestFailureBlock)failure;

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
               parameters:(NSDictionary *)parameters
                 progress:(SIRequestProgressBlock)progress
            cacheResponse:(SIRequestCacheBlock)cacheResponse
                 succeess:(SIRequestSuccessBlock)success
                  failure:(SIRequestFailureBlock)failure;

/**
 不带缓存的GET请求,数据会自动转换为JSON,解析XML需要设置ResponseSerializer,如果转换失败,会以@{@"result":reponse}格式返回

 @param url 请求地址
 @param parameters 请求参数
 @param success 成功回调
 @param failure 失败回调
 @return 返回当前task
 */
+ (NSURLSessionTask *)POST:(NSString *)url
                parameters:(NSDictionary *)parameters
                   success:(SIRequestSuccessBlock)success
                   failure:(SIRequestFailureBlock)failure;

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
                parameters:(NSDictionary *)parameters
                  progress:(SIRequestProgressBlock)progress
             cacheResponse:(SIRequestCacheBlock)cacheResponse
                   success:(SIRequestSuccessBlock)success
                   failure:(SIRequestFailureBlock)failure;

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
                             parameters:(NSDictionary *)parameters
                                   name:(NSString *)name
                               filePath:(NSString *)path
                               progress:(SIRequestProgressBlock)progress
                                success:(SIRequestSuccessBlock)success
                                failure:(SIRequestFailureBlock)failure;

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
                              parameters:(NSDictionary *)parameters
                                    name:(NSString *)name
                             maxFileSize:(double)size
                                  images:(NSArray *)images
                               fileNames:(NSArray *)fileNames
                               imageType:(NSString *)imageType
                                progress:(SIRequestProgressBlock)progress
                                 success:(SIRequestSuccessBlock)success
                                 failure:(SIRequestFailureBlock)failure;


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
                             progress:(SIRequestProgressBlock)progress
                              success:(void(^)(NSString *filePath))success
                              failure:(SIRequestFailureBlock)failure;

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
