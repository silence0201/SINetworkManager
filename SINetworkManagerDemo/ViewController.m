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
    [SINetworkManager setResponseSerializer:SIResponseSerializerXML] ;
    [SINetworkManager GET:@"http://www.w3school.com.cn/example/xmle/note.xml" parameters:nil succeess:^(NSURLSessionTask * _Nonnull task, NSDictionary * _Nonnull responseObject) {
    } failure:^(NSURLSessionTask * _Nonnull task, NSError * _Nonnull error) {
        
    }] ;

    [SINetworkManager setResponseSerializer:SIResponseSerializerJSON] ;
    [SINetworkManager GET:@"https://api.douban.com/v2/movie/coming_soon" parameters:nil succeess:^(NSURLSessionTask * _Nonnull task, NSDictionary * _Nonnull responseObject) {
        NSLog(@"请求成功:%@",responseObject) ;
    } failure:^(NSURLSessionTask * _Nonnull task, NSError * _Nonnull error) {
        NSLog(@"请求失败:%@",error) ;
    }] ;
}

- (void)networkStatusChange {
    // NSLog(@"当前网络状态：%ld",[SINetworkManager networkStatusType]);
}


@end
