# SINetworkManager
A NetworkManager With AFNetworking And YYCache

## 安装
### 1. 手动安装
下载项目后,将项目目录下`SINetworkManager`拖入项目中

### 2. CocoaPods安装
	
	pod 'SINetworkManager', '~> 1.0'
	
# 用法

1. 导入头文件

	```objective-c
	#import "SINetworkManager.h"
	```

2. 监听网络变化
		
	```objective-c
	[SINetworkManager networkStatusChageWithBlock:^(SINetworkStatusType status) {
    		NSLog(@"%ld",status) ;
    }];
    ```
    	
3. 请求数据,默认数据会先解析为JSON,否则解析为String,如果转换失败返回原数据
	
	```objective-c
	[SINetworkManager GET:@"https://www.v2ex.com/api/topics/hot.json" parameters:nil succeess:^(NSURLSessionTask * _Nonnull task, NSDictionary * _Nonnull responseObject) {
        
    } failure:^(NSURLSessionTask * _Nonnull task, NSError * _Nonnull error) {
        
    }] ;
    ```
    	
4. 获取可配置对象,可以动态修改请求过程中的一些参数信息
	
	```objective-c
	[SINetworkManager sharedConfig] ;
	```		
5. 缓存信息回调
	
	```objective-c
	[SINetworkCache cacheForURL:@"http://www.baidu.com" parameters:nil withBlock:^(id responseCache) {
    		NSLog(@"%@",responseCache) ;
    }] ;
    ```
    	
6. 如果数据为XML,自动解析


	```objective-c
    [SINetworkManager GET:@"http://www.w3school.com.cn/example/xmle/plant_catalog.xml" parameters:nil succeess:^(NSURLSessionTask * _Nonnull task, NSDictionary * _Nonnull responseObject) {
    } failure:^(NSURLSessionTask * _Nonnull task, NSError * _Nonnull error) {
        
    }] ;
    ```
    
7. 缓存支持,会自动在结果后面添加cacheTime作为判断是否有效

	```objective-c
    NSDictionary *cache1 = [SINetworkCache cacheForURL:@"http://www.w3school.com.cn/example/xmle/plant_catalog.xml"  parameters:nil];
    NSLog(@"%@",cache1);
    ```
    	

## SINetworkManager
SINetworkManager is available under the MIT license. See the LICENSE file for more info.
