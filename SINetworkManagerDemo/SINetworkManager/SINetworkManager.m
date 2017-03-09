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
#define SILog(...) printf("\n***********************start****************************\n[%s] %s [第%d行]\n%s\n*********************end********************************\n", __TIME__ ,__PRETTY_FUNCTION__ ,__LINE__, [[NSString stringWithFormat:__VA_ARGS__] UTF8String])
#else
#define SILog(...)
#endif

#define force_inline __inline__ __attribute__((always_inline))

NSString * const SINetworkStatusDidChangeNotification = @"com.alamofire.networking.reachability.change" ;
NSString * const SINetworkingReachabilityNotificationStatusItem = @"AFNetworkingReachabilityNotificationStatusItem" ;

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

#pragma mark --- UIImage compress
@interface UIImage (Compress)
- (NSData *)zipImageWithMaxSize:(CGFloat)size ;
@end

#pragma mark ---- SINetworkManager
static NSString *const SINetworkDefaultCookie = @"SINetworkDefaultCookie";
static dispatch_semaphore_t _semaphore ;
static SINetworkConfig *_config ;
static AFHTTPSessionManager *_sessionManager;
static NSMutableArray <NSURLSessionTask *>*_allSessionTask;
@implementation SINetworkManager

#pragma mark --- 初始化
+ (void)initialize{
    _semaphore = dispatch_semaphore_create(1);
    [[AFNetworkReachabilityManager sharedManager] startMonitoring] ;
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
    if (![self isNetwork]) {
        return SINetworkStatusNotReachable ;
    }
    if ([self isWiFiNetwork]) {
        return SINetworkStatusReachableViaWiFi ;
    }
    
    if ([self isWWANNetwork]){
        return SINetworkStatusReachableViaWWAN ;
    }
    
    return SINetworkStatusUnknow;
    
    
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

#pragma mark --- AFHTTPSessionManager
+ (AFHTTPSessionManager *)manager{
    if (!_sessionManager) {
         [self setConfig:[self sharedConfig]] ;
    }
    return _sessionManager ;
}

+ (void)setConfig:(SINetworkConfig *)config{
    _config = config ;
    _allSessionTask = [NSMutableArray array] ;
    // 所有请求公用一个AFHTTPSessionManager
    _sessionManager = [[AFHTTPSessionManager alloc]initWithBaseURL:[NSURL URLWithString:_config.baseURL]] ;
    _sessionManager.requestSerializer.timeoutInterval = _config.timeoutInterval ;
    [_config.allHTTPHeaderFields enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        [_sessionManager.requestSerializer setValue:obj forHTTPHeaderField:key] ;
    }] ;
    _sessionManager.requestSerializer = _config.requestSerializerType == 0 ? [AFHTTPRequestSerializer serializer] : [AFJSONRequestSerializer serializer];
    _sessionManager.responseSerializer = [AFHTTPResponseSerializer serializer];
    _sessionManager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/html", @"text/json", @"text/plain", @"text/javascript", @"text/xml", @"image/*", nil] ;
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:_config.networkActivityIndicatorEnabled] ;
}

+ (SINetworkConfig *)sharedConfig{
    if(!_config){
        _config = [SINetworkConfig defaultConfig] ;
    }
    return _config ;
}

+ (void)setRequestSerializer:(SIRequestSerializerType)requestSerializer{
    _config.requestSerializerType = requestSerializer ;
    _sessionManager.requestSerializer = requestSerializer == SIRequestSerializerHTTP ? [AFHTTPRequestSerializer serializer] : [AFJSONRequestSerializer serializer] ;
}

+ (void)setResponseSerializer:(SIResponseSerializerType)responseSerializer{
    _config.responseSerializerType = responseSerializer ;
    _sessionManager.responseSerializer = responseSerializer == SIRequestSerializerJSON ? [AFJSONResponseSerializer serializer] : [AFHTTPResponseSerializer serializer] ;
}

+ (void)setRequestTimeoutInterval:(NSTimeInterval)time{
    _config.timeoutInterval = time ;
    _sessionManager.requestSerializer.timeoutInterval = time ;
}

+ (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field{
    [_config setValue:value forHTTPHeaderField:field] ;
    [_sessionManager.requestSerializer setValue:value forHTTPHeaderField:field] ;
}

+ (void)openNetworkActivityIndicator:(BOOL)open{
    _config.networkActivityIndicatorEnabled = open ;
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:open] ;
}

+ (void)setSecurityPolicyWithCerPath:(NSString *)cerPath validatesDomainName:(BOOL)validatesDomainName{
    NSData *cerData = [NSData dataWithContentsOfFile:cerPath] ;
    // 使用证书模式
    AFSecurityPolicy *securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate] ;
    // 如果需要验证自建证书(无效证书),需要设置为YES
    securityPolicy.allowInvalidCertificates = YES ;
    // validatesDomainName 是否需要验证域名，默认为YES;
    // 假如证书的域名与你请求的域名不一致，需把该项设置为NO；如设成NO的话，即服务器使用其他可信任机构颁发的证书，也可以建立连接，这个非常危险，建议打开。
    // 置为NO，主要用于这种情况：客户端请求的是子域名，而证书上的是另外一个域名。因为SSL证书上的域名是独立的，假如证书上注册的域名是www.google.com，那么mail.google.com是无法验证通过的；当然，有钱可以注册通配符的域名*.google.com，但这个还是比较贵的。
    // 如置为NO，建议自己添加对应域名的校验逻辑。
    securityPolicy.validatesDomainName = validatesDomainName ;
    securityPolicy.pinnedCertificates = [[NSSet alloc]initWithObjects:cerData, nil] ;
    [_sessionManager setSecurityPolicy:securityPolicy] ;
}

#pragma mark ---Private
static force_inline void addSessionDataTask(__unsafe_unretained NSURLSessionDataTask *task){
    dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER) ;
    [_allSessionTask addObject:task];
    dispatch_semaphore_signal(_semaphore) ;
}

static force_inline void addSessionDownTask(__unsafe_unretained  NSURLSessionDownloadTask*task){
    dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER) ;
    [_allSessionTask addObject:task];
    dispatch_semaphore_signal(_semaphore) ;
}

static force_inline void removeSessionDataTask(__unsafe_unretained NSURLSessionDataTask *task){
    dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER) ;
    [_allSessionTask removeObject:task];
    dispatch_semaphore_signal(_semaphore) ;
}

static force_inline void removeSessionDownTask(__unsafe_unretained NSURLSessionDownloadTask *task){
    dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER) ;
    [_allSessionTask removeObject:task];
    dispatch_semaphore_signal(_semaphore) ;
}

static force_inline void networkCookieConfig(){
    _config.cookieEnabled ? setCookie() : nil;
}

static force_inline void setCookie(){
    NSData *cookiesdata = [[NSUserDefaults standardUserDefaults] objectForKey:SINetworkDefaultCookie];
    if([cookiesdata length]) {
        NSArray *cookies = [NSKeyedUnarchiver unarchiveObjectWithData:cookiesdata];
        NSHTTPCookie *cookie;
        for (cookie in cookies) {
            [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookie];
        }
    }
}

static force_inline void showNetworkActivityIndicator(){
    [AFNetworkActivityIndicatorManager sharedManager].enabled = _config.networkActivityIndicatorEnabled;
}

static force_inline void hideNetworkActivityIndicator(){
    [AFNetworkActivityIndicatorManager sharedManager].enabled = NO;
}

+ (void)logRequestCancel:(NSURLSessionDataTask *)task para:(NSDictionary *)para {
    SILog(@"请求的地址是：%@\n上传的参数为：%@\n--->该请求已取消<---",task.currentRequest.URL,para);
}

+ (void)logRequestSuccess:(NSURLSessionDataTask *)task para:(NSDictionary *)para response:(NSDictionary *)response {
    SILog(@"请求的地址是：%@\n上传的参数为：%@\n返回的数据:%@",task.currentRequest.URL,para,response);
}

+ (void)logRequestFailure:(NSURLSessionDataTask *)task para:(NSDictionary *)para error:(NSError *)error {
    SILog(@"请求的地址是：%@\n上传的参数为：%@\n返回的错误:\n%@",task.currentRequest.URL,para,error);
}

+ (NSDictionary *)addCommonParameters:(NSDictionary *)parameters{
    NSMutableDictionary *mDic = [NSMutableDictionary dictionaryWithDictionary:parameters];
    if (_config.commonParas) {
        [mDic addEntriesFromDictionary:_config.commonParas];
    }
    return mDic.copy;
}

+ (NSDictionary *)convertResponse:(id)response withTask:(NSURLSessionDataTask *)task{
    if (!response) return @{@"result":@"没有任何数据"};
    NSData *data = [NSData dataWithData:response];
    if ([task.response.textEncodingName compare:@"gbk" options:NSCaseInsensitiveSearch] == NSOrderedSame) {
        NSStringEncoding enc =CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
        NSString *GBKString = [[NSString alloc]initWithData:response encoding:enc];
        data = [GBKString dataUsingEncoding:NSUTF8StringEncoding];
    }
    if (!data) {
        SILog(@"%@,返回的数据有误，请检查",task.currentRequest.URL);
        return @{@"result":response};
    }
    
    // 转化为XML需要规定
    if(_config.responseSerializerType == SIResponseSerializerXML){
        _YYXMLDictionaryParser *parser = [[_YYXMLDictionaryParser alloc] initWithData:data];
        NSDictionary *dic = [parser result];
        if ([NSJSONSerialization isValidJSONObject:dic]) {
            return dic;
        }
        SILog(@"%@,返回的数据无法转换为可用XML格式，请检查",task.currentRequest.URL);
    }
    
    // 自动转化
    NSDictionary *dic;
    dic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
    if ([NSJSONSerialization isValidJSONObject:dic]) {
        return dic;
    }
    
    NSString *str = [[NSString alloc]initWithData:response encoding:NSUTF8StringEncoding] ;
    if (str.length > 0) {
        return @{@"result":str} ;
    }
    
    return @{@"result":response};
}

#pragma mark --- 请求数据
+ (NSURLSessionTask *)GET:(NSString *)url
               parameters:(NSDictionary *)parameters
                 succeess:(SIRequestSuccessBlock)success
                  failure:(SIRequestFailureBlock)failure{
    return [self GET:url parameters:parameters progress:nil cacheResponse:nil succeess:success failure:failure] ;
}

+ (NSURLSessionTask *)GET:(NSString *)url
               parameters:(NSDictionary *)parameters
                 progress:(SIRequestProgressBlock)progress
            cacheResponse:(SIRequestCacheBlock)cacheResponse
                 succeess:(SIRequestSuccessBlock)success
                  failure:(SIRequestFailureBlock)failure{
    if(cacheResponse){
        cacheResponse([SINetworkCache cacheForURL:url parameters:parameters]) ;
    }
    networkCookieConfig();
    showNetworkActivityIndicator();
    NSDictionary *newParam = [self addCommonParameters:parameters];
    NSURLSessionDataTask *task = [[self manager] GET:url parameters:newParam progress:^(NSProgress * _Nonnull downloadProgress) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            progress ? progress(downloadProgress) : nil;
        });
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        removeSessionDataTask(task);
        hideNetworkActivityIndicator();
        NSDictionary *result = [self convertResponse:responseObject withTask:task];
        cacheResponse ? [SINetworkCache setCache:result URL:url parameters:parameters] : nil;
        success ? success(task, result) : nil;
        // 打印日志
        [self logRequestSuccess:task para:parameters response:result];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        removeSessionDataTask(task);
        hideNetworkActivityIndicator();
        if (error.code == -999 ) {
            [self logRequestCancel:task para:parameters];
            return ;
        } else {
            failure ? failure(task,error) : nil;
            [self logRequestFailure:task para:parameters error:error];
        }
    }] ;
    addSessionDataTask(task) ;
    return task ;
}

+ (NSURLSessionTask *)POST:(NSString *)url parameters:(NSDictionary *)parameters success:(SIRequestSuccessBlock)success failure:(SIRequestFailureBlock)failure{
    return  [self POST:url parameters:parameters progress:nil cacheResponse:nil success:success failure:failure] ;
}

+ (NSURLSessionTask *)POST:(NSString *)url parameters:(NSDictionary *)parameters progress:(SIRequestProgressBlock)progress cacheResponse:(SIRequestCacheBlock)cacheResponse success:(SIRequestSuccessBlock)success failure:(SIRequestFailureBlock)failure{
    cacheResponse ? cacheResponse([SINetworkCache cacheForURL:url parameters:parameters]) : nil;
    networkCookieConfig();
    showNetworkActivityIndicator();
    NSDictionary *newParam = [self addCommonParameters:parameters];
    NSURLSessionDataTask *sessionTask = [[self manager] POST:url parameters:newParam progress:^(NSProgress * _Nonnull uploadProgress) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            progress ? progress(uploadProgress) : nil;
        });
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        hideNetworkActivityIndicator();
        removeSessionDataTask(task);
        NSDictionary *result = [self convertResponse:responseObject withTask:task];
        cacheResponse ? [SINetworkCache setCache:result URL:url parameters:parameters] : nil;
        success ? success(task, result) : nil;
        [self logRequestSuccess:task para:parameters response:result];
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        removeSessionDataTask(task);
        hideNetworkActivityIndicator();
        if (error.code == -999) {
            [self logRequestCancel:task para:parameters];
            return ;
        } else {
            failure ? failure(task,error) : nil;
            [self logRequestFailure:task para:parameters error:error];
        }
    }];
    addSessionDataTask(sessionTask);
    return sessionTask;
}

+ (NSURLSessionTask *)uploadFileWithURL:(NSString *)url
                             parameters:(NSDictionary *)parameters
                                   name:(NSString *)name
                               filePath:(NSString *)path
                               progress:(SIRequestProgressBlock)progress
                                success:(SIRequestSuccessBlock)success
                                failure:(SIRequestFailureBlock)failure{
    networkCookieConfig();
    showNetworkActivityIndicator();
    NSDictionary *newParam = [self addCommonParameters:parameters];
    NSURLSessionDataTask *sessionTask = [_sessionManager POST:url parameters:newParam constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        NSError *error = nil;
        [formData appendPartWithFileURL:[NSURL URLWithString:path] name:name error:&error];
        (failure && error) ? failure(nil,error) : nil;
        error ? NSLog(@"上传失败") : nil;
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            progress ? progress(uploadProgress) : nil;
        });
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        hideNetworkActivityIndicator();
        NSDictionary *result = [self convertResponse:responseObject withTask:task];
        success ? success(task, result) : nil;
        removeSessionDataTask(task);
        [self logRequestSuccess:task para:parameters response:result];
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        removeSessionDataTask(task);
        hideNetworkActivityIndicator();
        if (error.code == -999 ) {
            [self logRequestCancel:task para:parameters];
            return ;
        } else {
            failure ? failure(task,error) : nil;
            [self logRequestFailure:task para:parameters error:error];
        }
    }];
    addSessionDataTask(sessionTask);
    return sessionTask;
}

+ (NSURLSessionTask *)uploadImageWithURL:(NSString *)url
                              parameters:(NSDictionary *)parameters
                                    name:(NSString *)name
                             maxFileSize:(double)size
                                  images:(NSArray *)images
                               fileNames:(NSArray *)fileNames
                               imageType:(NSString *)imageType
                                progress:(SIRequestProgressBlock)progress
                                 success:(SIRequestSuccessBlock)success
                                 failure:(SIRequestFailureBlock)failure{
    NSAssert(images.count != 0, @"图片不能为空");
    // 默认时间命名
    if(!fileNames){
        NSMutableArray *array = [NSMutableArray array] ;
        for (int i = 0 ; i < images.count;i++ ){
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            formatter.dateFormat = @"yyyyMMddHHmmss";
            NSString *str = [formatter stringFromDate:[NSDate date]];
            NSString *imageFileName = [NSString stringWithFormat:@"%@%d.%@",str,i,imageType?:@"jpg"];
            [array addObject:imageFileName] ;
        }
        fileNames = array ;
    }
    NSAssert(images.count == fileNames.count, @"图片和文件名数量须相等");
    
    networkCookieConfig();
    showNetworkActivityIndicator();
    NSDictionary *newParam = [self addCommonParameters:parameters];
    NSURLSessionDataTask *sessionTask = [_sessionManager POST:url parameters:newParam constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        for (int i = 0; i < images.count; i++) {
            NSData *data;
            if (size > 0) {
                UIImage *image = images[i] ;
                data = [image zipImageWithMaxSize:size] ;
            } else {
                data = UIImageJPEGRepresentation(images[i],1);
            }
            
            [formData appendPartWithFileData:data name:name fileName:fileNames[i] mimeType:imageType ? : [NSString stringWithFormat:@"image/jpg"]];
        }
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            progress ? progress(uploadProgress) : nil;
        });
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        hideNetworkActivityIndicator();
        removeSessionDataTask(task);
        NSDictionary *result = [self convertResponse:responseObject withTask:task];
        success ? success(task, result) : nil;
        [self logRequestSuccess:task para:parameters response:result];
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        removeSessionDataTask(task);
        hideNetworkActivityIndicator();
        if (error.code == -999 ) {
            [self logRequestCancel:task para:parameters];
            return ;
        } else {
            failure ? failure(task,error) : nil;
            [self logRequestFailure:task para:parameters error:error];
        }
    }];
    addSessionDataTask(sessionTask);
    return sessionTask;
}

+ (NSURLSessionTask *)downloadWithURL:(NSString *)URL fileDir:(NSString *)fileDir progress:(SIRequestProgressBlock)progress success:(void (^)(NSString * _Nonnull))success failure:(SIRequestFailureBlock)failure{
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:URL]];
    networkCookieConfig();
    showNetworkActivityIndicator();
    NSURLSessionDownloadTask *task = [_sessionManager downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
        //下载进度
        dispatch_sync(dispatch_get_main_queue(), ^{
            progress ? progress(downloadProgress) : nil;
        });
    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        //拼接缓存目录
        NSString *downloadDir = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:fileDir ? fileDir : @"Download"];
        //打开文件管理器
        NSFileManager *fileManager = [NSFileManager defaultManager];
        //创建Download目录
        [fileManager createDirectoryAtPath:downloadDir withIntermediateDirectories:YES attributes:nil error:nil];
        //拼接文件路径
        NSString *filePath = [downloadDir stringByAppendingPathComponent:response.suggestedFilename];
        //返回文件位置的URL路径
        return [NSURL fileURLWithPath:filePath];
        
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        hideNetworkActivityIndicator();
        removeSessionDownTask(task);
        if(failure && error) {failure(task,error) ; return ;};
        success ? success(filePath.absoluteString /** NSURL->NSString*/) : nil;
    }];
    //开始下载
    [task resume];
    // 添加sessionTask到数组
    task ? addSessionDownTask(task): nil ;
    return task;
}

#pragma mark --- 取消请求
+ (void)cancelTaskWithURL:(NSString *)URL {
    if (!URL) return;
    dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER) ;
    [_allSessionTask enumerateObjectsUsingBlock:^(NSURLSessionTask * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.currentRequest.URL.absoluteString containsString:URL]) {
            [obj cancel];
            [_allSessionTask removeObject:obj];
            //*stop = YES; //考虑在一个时间段向同一URL发起多次请求的情况
        }
    }];
    dispatch_semaphore_signal(_semaphore) ;
}


+ (void)cancelAllTask {
    dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER) ;
    [_allSessionTask enumerateObjectsUsingBlock:^(NSURLSessionTask * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj cancel];
    }];
    [_allSessionTask removeAllObjects];
    dispatch_semaphore_signal(_semaphore) ;
}

#pragma mark - cookie 设置
+ (void)getCookie:(NSString *)url{
    // 获取并保存cookie
    NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[NSURL URLWithString:url]] ;
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:cookies];
    [[NSUserDefaults standardUserDefaults] setObject:data forKey:SINetworkDefaultCookie];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (void)setLocalCookieWithCookieName:(NSArray *)names values:(NSArray *)values originURL:(NSString *)url expires:(NSTimeInterval)expires {
#if DEBUG
    NSAssert(names.count == values.count && names.count != 0, @"name和value须一一对应且不为空");
#else
    if (names.count != values.count || names.count == 0) return;
#endif
    for (int i = 0; i < names.count; i++) {
        NSDictionary *property = @{NSHTTPCookieName :names[i],
                                   NSHTTPCookieValue : values[i],
                                   NSHTTPCookieOriginURL : url,
                                   NSHTTPCookieExpires : [NSDate dateWithTimeIntervalSinceNow:expires]};
        NSHTTPCookie *cookie = [NSHTTPCookie cookieWithProperties:property];
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookie];
    }
}

///清除cookie
+ (void)clearCookie {
    NSData *cookiesdata = [[NSUserDefaults standardUserDefaults] objectForKey:SINetworkDefaultCookie];
    if([cookiesdata length]) {
        NSArray *cookies = [NSKeyedUnarchiver unarchiveObjectWithData:cookiesdata];
        NSHTTPCookie *cookie;
        for (cookie in cookies) {
            [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
            [[NSURLCache sharedURLCache] removeAllCachedResponses];
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:SINetworkDefaultCookie];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    }
}


@end




@implementation UIImage (Compress)

- (NSData *)zipImageWithMaxSize:(CGFloat)size{
    if (!self) {
        return nil;
    }
    CGFloat maxFileSize = size*1024*1024;
    CGFloat compression = 0.9f;
    NSData *compressedData = UIImageJPEGRepresentation(self, compression);
    
    while ([compressedData length] > maxFileSize) {
        compression *= 0.9;
        compressedData = UIImageJPEGRepresentation ([self compressWithNewWidth:self.size.width*compression],compression) ;
    }
    return compressedData;
}

- (UIImage *)compressWithNewWidth:(CGFloat)newWidth{
    if (!self) return nil;
    float imageWidth = self.size.width;
    float imageHeight = self.size.height;
    float width = newWidth;
    float height = self.size.height/(self.size.width/width);
    
    float widthScale = imageWidth /width;
    float heightScale = imageHeight /height;
    
    UIGraphicsBeginImageContext(CGSizeMake(width, height));
    if (widthScale > heightScale) {
        [self drawInRect:CGRectMake(0, 0, imageWidth /heightScale , height)];
    } else {
        [self drawInRect:CGRectMake(0, 0, width , imageHeight /widthScale)];
    }
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

@end

#pragma mark - 中文输出
#pragma mark -
#ifdef DEBUG
@implementation NSArray (LocaleLog)

- (NSString *)descriptionWithLocale:(id)locale {
    NSMutableString *mStr = [NSMutableString stringWithString:@"[\n"];
    [self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [mStr appendFormat:@"\t%@,\n", obj];
    }];
    [mStr appendString:@"]"];
    NSRange range = [mStr rangeOfString:@"," options:NSBackwardsSearch];
    if (range.location != NSNotFound){
        [mStr deleteCharactersInRange:range];
    }
    return mStr;
}

@end

@implementation NSDictionary (LocaleLog)

- (NSString *)descriptionWithLocale:(id)locale {
    NSMutableString *mStr = [NSMutableString stringWithString:@"{\n"];
    [self enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [mStr appendFormat:@"\t%@ = %@;\n", key, obj];
    }];
    [mStr appendString:@"}"];
    NSRange range = [mStr rangeOfString:@"," options:NSBackwardsSearch];
    if (range.location != NSNotFound){
        [mStr deleteCharactersInRange:range];
    }
    return mStr;
}
@end
#endif

