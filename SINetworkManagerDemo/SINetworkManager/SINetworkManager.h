//
//  SINetworkManager.h
//  SINetworkManagerDemo
//
//  Created by 杨晴贺 on 2017/3/8.
//  Copyright © 2017年 Silence. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger,SIRequestSerializerType){
    SIRequestSerializerHTTP = 0, ///< 请求的数据格式为二进制数据
    SIRequestSerializerJSON     ///< 请求数据为JSON格式
};

typedef NS_ENUM(NSInteger,SIResponseSerializerType){
    SIResponseSerializerHTTP = 0, ///< 返回的数据格式为二进制数据
    SIResponseSerializerJSON,     ///< 返回数据为JSON格式
    SIResponseSerializerXML       ///< 返回的数据为XML
};

NS_ASSUME_NONNULL_BEGIN

typedef void(^SIRequestCacheBlock)(id responseCache); ///>  缓存Block

@interface SINetworkCache : NSObject

+ (void)setCache:(id)data URL:(NSString *)url parameters:(NSDictionary *)parameters ;

+ (id)cacheForURL:(NSString *)url parameters:(NSDictionary *)parameters ;
+ (id)cacheForURL:(NSString *)url parameters:(NSDictionary *)parameters withBlock:(SIRequestCacheBlock)block ;

+ (NSInteger)getAllCacheSize ;

+ (void)removeAllCache ;

@end

@interface SINetworkConfig : NSObject

@property (nonatomic,copy) NSString *baseURL ; ///> 根地址
@property (nonatomic,copy) NSDictionary *commonParas ; ///> 公共参数
@property (nonatomic,assign) NSTimeInterval timeoutInterval ; ///> 超时时间,默认为30s

@property (nonatomic,assign) SIRequestSerializerType requestSerializerType ;   ///> 请求数据类型,默认是二进制类型
@property (nonatomic,assign) SIResponseSerializerType responseSerializerType ;  ///> 返回数据类型

@property (nonatomic,assign) BOOL networkActivityIndicatorEnabled ; ///> 是否显示转动的菊花
@property (nonatomic,assign) BOOL cookieEnabled ;   ///> 是否使用Cookie
@property (nonatomic,assign) BOOL debugLogEnable ;  ///> 是否打开调试信息

@property (nonatomic,readonly,copy) NSDictionary *allHTTPHeaderFields ;   ///> 设置的请求头信息
- (void)setValue:(NSString *)value forHTTPHeaderField:(nonnull NSString *)field ; ///> 设置请求头信息

+ (instancetype)defaultConfig ;  ///> 默认设置

@end

@interface SINetworkManager : NSObject

@end

NS_ASSUME_NONNULL_END
