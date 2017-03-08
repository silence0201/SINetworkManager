//
//  SINetworkManager.m
//  SINetworkManagerDemo
//
//  Created by 杨晴贺 on 2017/3/8.
//  Copyright © 2017年 Silence. All rights reserved.
//

#import "SINetworkManager.h"
#import <YYCache/YYCache.h>
#import <AFNetworking/AFNetworking.h>
#import <AFNetworking/AFNetworkActivityIndicatorManager.h>

#ifdef DEBUG
#define SILog(...) printf("[%s] %s [第%d行]: %s\n", __TIME__ ,__PRETTY_FUNCTION__ ,__LINE__, [[NSString stringWithFormat:__VA_ARGS__] UTF8String])
#else
#define SILog(...)
#endif



NSString *const SINetworkStatusDidChangeNotification = @"SINetworkingReachabilityDidChangeNotification";


#pragma mark - 来自YYKit的XML解析
#pragma mark -

@interface _YYXMLDictionaryParser : NSObject <NSXMLParserDelegate>
@end

@implementation _YYXMLDictionaryParser {
    NSMutableDictionary *_root;
    NSMutableArray *_stack;
    NSMutableString *_text;
}

- (instancetype)initWithData:(NSData *)data {
    self = super.init;
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:data];
    [parser setDelegate:self];
    [parser parse];
    return self;
}

- (instancetype)initWithString:(NSString *)xml {
    NSData *data = [xml dataUsingEncoding:NSUTF8StringEncoding];
    return [self initWithData:data];
}

- (NSDictionary *)result {
    return _root;
}

#pragma mark - NSXMLParserDelegate

#define XMLText @"_text"
#define XMLName @"_name"
#define XMLPref @"_"

- (void)textEnd {
    _text = [_text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].mutableCopy;
    if (_text.length) {
        NSMutableDictionary *top = _stack.lastObject;
        id existing = top[XMLText];
        if ([existing isKindOfClass:[NSArray class]]) {
            [existing addObject:_text];
        } else if (existing) {
            top[XMLText] = [@[existing, _text] mutableCopy];
        } else {
            top[XMLText] = _text;
        }
    }
    _text = nil;
}

- (void)parser:(__unused NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(__unused NSString *)namespaceURI qualifiedName:(__unused NSString *)qName attributes:(NSDictionary *)attributeDict {
    [self textEnd];
    
    NSMutableDictionary *node = [NSMutableDictionary new];
    if (!_root) node[XMLName] = elementName;
    if (attributeDict.count) [node addEntriesFromDictionary:attributeDict];
    
    if (_root) {
        NSMutableDictionary *top = _stack.lastObject;
        id existing = top[elementName];
        if ([existing isKindOfClass:[NSArray class]]) {
            [existing addObject:node];
        } else if (existing) {
            top[elementName] = [@[existing, node] mutableCopy];
        } else {
            top[elementName] = node;
        }
        [_stack addObject:node];
    } else {
        _root = node;
        _stack = [NSMutableArray arrayWithObject:node];
    }
}

- (void)parser:(__unused NSXMLParser *)parser didEndElement:(__unused NSString *)elementName namespaceURI:(__unused NSString *)namespaceURI qualifiedName:(__unused NSString *)qName {
    [self textEnd];
    
    NSMutableDictionary *top = _stack.lastObject;
    [_stack removeLastObject];
    
    NSMutableDictionary *left = top.mutableCopy;
    [left removeObjectsForKeys:@[XMLText, XMLName]];
    for (NSString *key in left.allKeys) {
        [left removeObjectForKey:key];
        if ([key hasPrefix:XMLPref]) {
            left[[key substringFromIndex:XMLPref.length]] = top[key];
        }
    }
    if (left.count) return;
    
    NSMutableDictionary *children = top.mutableCopy;
    [children removeObjectsForKeys:@[XMLText, XMLName]];
    for (NSString *key in children.allKeys) {
        if ([key hasPrefix:XMLPref]) {
            [children removeObjectForKey:key];
        }
    }
    if (children.count) return;
    
    NSMutableDictionary *topNew = _stack.lastObject;
    NSString *nodeName = top[XMLName];
    if (!nodeName) {
        for (NSString *name in topNew) {
            id object = topNew[name];
            if (object == top) {
                nodeName = name; break;
            } else if ([object isKindOfClass:[NSArray class]] && [object containsObject:top]) {
                nodeName = name; break;
            }
        }
    }
    if (!nodeName) return;
    
    id inner = top[XMLText];
    if ([inner isKindOfClass:[NSArray class]]) {
        inner = [inner componentsJoinedByString:@"\n"];
    }
    if (!inner) return;
    
    id parent = topNew[nodeName];
    if ([parent isKindOfClass:[NSArray class]]) {
        NSArray *parentAsArray = parent;
        parent[parentAsArray.count - 1] = inner;
    } else {
        topNew[nodeName] = inner;
    }
}

- (void)parser:(__unused NSXMLParser *)parser foundCharacters:(NSString *)string {
    if (_text) [_text appendString:string];
    else _text = [NSMutableString stringWithString:string];
}

- (void)parser:(__unused NSXMLParser *)parser foundCDATA:(NSData *)CDATABlock {
    NSString *string = [[NSString alloc] initWithData:CDATABlock encoding:NSUTF8StringEncoding];
    if (_text) [_text appendString:string];
    else _text = [NSMutableString stringWithString:string];
}

#undef XMLText
#undef XMLName
#undef XMLPref
@end


#pragma mark --- SINetworkCache
static NSString *const NetworkCacheName = @"SINetworkCache" ;
static YYCache *_networkCache ;
@implementation SINetworkCache

+ (void)initialize{
    _networkCache = [YYCache cacheWithName:NetworkCacheName] ;
}

+ (void)setCache:(id)data URL:(NSString *)url parameters:(NSDictionary *)parameters{
    NSString *cacheKey = [self _keyWithURL:url paramters:parameters] ;
    [_networkCache setObject:data forKey:cacheKey] ;
}

+ (id)cacheForURL:(NSString *)url parameters:(NSDictionary *)parameters{
    NSString *cacheKey = [self _keyWithURL:url paramters:parameters] ;
    return  [_networkCache objectForKey:cacheKey] ;
}

+ (id)cacheForURL:(NSString *)url parameters:(NSDictionary *)parameters withBlock:(SIRequestCacheBlock)block{
    NSString *cacheKey = [self _keyWithURL:url paramters:parameters] ;
    if(block){
        [_networkCache objectForKey:cacheKey withBlock:^(NSString * _Nonnull key, id<NSCoding>  _Nonnull object) {
            dispatch_async(dispatch_get_main_queue(), ^{
                block(object) ;
            }) ;
        }] ;
    }
    return  [_networkCache objectForKey:cacheKey] ;
}


+ (void)removeAllCache{
    [_networkCache.diskCache removeAllObjects] ;
}

+ (NSInteger)getAllCacheSize{
    return [_networkCache.diskCache totalCost] ;
}

#pragma mark --- 私有方法
+ (NSString *)_keyWithURL:(NSString *)url paramters:(NSDictionary *)para{
    if (!para)  return url ;
    
    NSData *stringData = [NSJSONSerialization dataWithJSONObject:para options:0 error:nil] ;
    NSString *paraString = [[NSString alloc]initWithData:stringData encoding:NSUTF8StringEncoding] ;
    
    // 拼接
    NSString *cacheKey = [NSString stringWithFormat:@"%@%@",url,paraString] ;
    
    return cacheKey ;
}

@end

#pragma mark ---- SINetworkConfig
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

#pragma mark ---- SINetworkManager
static SINetworkStatusType _currentNetworkStatus ;
static AFHTTPSessionManager *_sessionManager;
static NSMutableArray <NSURLSessionTask *>*_allSessionTask;
static dispatch_semaphore_t _semaphore ;
@implementation SINetworkManager{
    SINetworkConfig *_config ;
}

#pragma mark --- 初始化
+ (void)load{
    _allSessionTask = [NSMutableArray array] ;
    _currentNetworkStatus = SINetworkStatusUnknow ;
    _semaphore = dispatch_semaphore_create(1);
    [[AFNetworkReachabilityManager sharedManager] startMonitoring] ;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkStatusChanged:) name:AFNetworkingReachabilityDidChangeNotification object:nil] ;
    
}

- (void)networkStatusChanged:(NSNotification *)noti{
    NSNumber *number = [noti.userInfo objectForKey:AFNetworkingReachabilityNotificationStatusItem] ;
    // 判断是什么类型
    switch ([number integerValue]) {
        case 0:
            _currentNetworkStatus = SINetworkStatusNotReachable ;
            break ;
        case 1:
            _currentNetworkStatus = SINetworkStatusReachableViaWWAN ;
            break ;
        case 2:
            _currentNetworkStatus = SINetworkStatusReachableViaWiFi ;
            break ;
        default:
            _currentNetworkStatus = SINetworkStatusUnknow ;
            break;
    }
    
    // 发送通知
    [[NSNotificationCenter defaultCenter] postNotificationName:SINetworkStatusDidChangeNotification object:nil userInfo:noti.userInfo] ;
}

#pragma mark --- init
- (instancetype)initWithConfig:(SINetworkConfig *)config{
    if (self = [super init]) {
        _config = config ;
        // 所有请求公用一个AFHTTPSessionManager
        _sessionManager = [[AFHTTPSessionManager alloc]initWithBaseURL:[NSURL URLWithString:_config.baseURL]] ;
        _sessionManager.requestSerializer.timeoutInterval = _config.timeoutInterval ;
        [_config.allHTTPHeaderFields enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            [_sessionManager.requestSerializer setValue:obj forHTTPHeaderField:key] ;
        }] ;
        _sessionManager.requestSerializer = config.requestSerializerType == 0 ? [AFHTTPRequestSerializer serializer] : [AFJSONRequestSerializer serializer];
        _sessionManager.responseSerializer = [AFHTTPResponseSerializer serializer];
        _sessionManager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/html", @"text/json", @"text/plain", @"text/javascript", @"text/xml", @"image/*", nil];
    }
    return self ;
}

- (instancetype)init{
    return [self initWithConfig:[SINetworkConfig defaultConfig]] ;
}

+ (instancetype)defaultManager{
    return [[self alloc]init] ;
}

#pragma mark --- 网络状态
+ (BOOL)isNetwork{
    return [AFNetworkReachabilityManager sharedManager].reachable ;
}

+ (BOOL)isWiFiNetwork{
    return [AFNetworkReachabilityManager sharedManager].reachableViaWiFi ;
}

+ (BOOL)isWWANNetwork{
    return [AFNetworkReachabilityManager sharedManager].reachableViaWWAN ;
}

+ (SINetworkStatusType)networkStatusType{
    return _currentNetworkStatus ;
}

+ (void)networkStatusChageWithBlock:(SINetworkStatusBlock)block{
    [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        switch (status) {
            case AFNetworkReachabilityStatusUnknown:
                SILog(@"未知网络情况") ;
                block ? block(SINetworkStatusUnknow) : nil ;
                break;
            case AFNetworkReachabilityStatusNotReachable:
                SILog(@"无网络") ;
                block ? block(SINetworkStatusNotReachable) : nil ;
                break ;
            case AFNetworkReachabilityStatusReachableViaWWAN :
                SILog(@"蜂窝网络") ;
                block ? block(SINetworkStatusReachableViaWWAN) : nil ;
                break ;
            case AFNetworkReachabilityStatusReachableViaWiFi:
                SILog(@"WIFI网络") ;
                block ? block(SINetworkStatusReachableViaWiFi) : nil ;
                break ;
        }
    }] ;
}

@end



