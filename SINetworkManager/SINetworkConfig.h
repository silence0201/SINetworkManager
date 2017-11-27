//
//  SINetworkConfig.h
//  SINetworkManagerDemo
//
//  Created by Silence on 2017/3/9.
//  Copyright © 2017年 Silence. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/** 配置 */
@interface SINetworkConfig : NSObject

/// 根地址,默认为空,如果需要设置需要创建新的Config
@property (nonatomic,copy) NSString *baseURL ;
/// 公共参数
@property (nonatomic,copy) NSDictionary *commonParas ;
/// 超时时间,默认为30s
@property (nonatomic,assign) NSTimeInterval timeoutInterval ;

/// 是否显示转动的菊花
@property (nonatomic,assign) BOOL networkActivityIndicatorEnabled ;
/// 是否使用Cookie
@property (nonatomic,assign) BOOL cookieEnabled ;

/// 请求头信息
@property (nonatomic,readonly,copy) NSDictionary *allHTTPHeaderFields ;
/// 设置请求头信息
- (void)setValue:(NSString *)value forHTTPHeaderField:(nonnull NSString *)field ;

/// 默认设置
+ (instancetype)defaultConfig ;

@end
NS_ASSUME_NONNULL_END

