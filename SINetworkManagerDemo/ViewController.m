//
//  ViewController.m
//  SINetworkManagerDemo
//
//  Created by Silence on 2017/3/8.
//  Copyright © 2017年 Silence. All rights reserved.
//

#import "ViewController.h"
#import "SINetworkManager.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // [SINetworkManager setLogEnabel:NO];  // 是否开启日志打印功能,默认为YES
    
    NSDictionary *params = @{@"Test":@"123",@"Test2":@"456"};
    
    [SINetworkManager GET:@"http://www.w3school.com.cn/example/xmle/plant_catalog.xml" parameters:params succeess:^(NSURLSessionTask * _Nonnull task, NSDictionary * _Nonnull responseObject) {
    } failure:^(NSURLSessionTask * _Nonnull task, NSError * _Nonnull error) {

    }] ;
    
    [SINetworkManager GET:@"https://api.douban.com/v2/movie/coming_soon" parameters:nil succeess:^(NSURLSessionTask * _Nonnull task, NSDictionary * _Nonnull responseObject) {
        // NSLog(@"请求成功:%@",responseObject) ;
    } failure:^(NSURLSessionTask * _Nonnull task, NSError * _Nonnull error) {
        // NSLog(@"请求失败:%@",error) ;
    }] ;
    
    // 缓存效果测试1
    // NSDictionary *cache1 = [SINetworkCache cacheForURL:@"http://www.w3school.com.cn/example/xmle/plant_catalog.xml"  parameters:nil];
    // NSLog(@"%@",cache1);
    
    // 缓存效果测试2
    // NSDictionary *cache2 = [SINetworkCache cacheForURL:@"https://api.douban.com/v2/movie/coming_soon" parameters:nil];
    // NSLog(@"%@",cache2);
    
    
}

- (void)networkStatusChange {
    // NSLog(@"当前网络状态：%ld",[SINetworkManager networkStatusType]);
}


@end
