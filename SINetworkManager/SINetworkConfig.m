//
//  SINetworkConfig.m
//  SINetworkManagerDemo
//
//  Created by 杨晴贺 on 2017/3/9.
//  Copyright © 2017年 Silence. All rights reserved.
//

#import "SINetworkConfig.h"

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

