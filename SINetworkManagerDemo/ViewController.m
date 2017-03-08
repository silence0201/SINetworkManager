//
//  ViewController.m
//  SINetworkManagerDemo
//
//  Created by 杨晴贺 on 2017/3/8.
//  Copyright © 2017年 Silence. All rights reserved.
//

#import "ViewController.h"
#import "SINetworkManager.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"当前网络状态：%ld",[SINetworkManager networkStatusType]);
    [SINetworkManager GET:@"https://www.v2ex.com/api/topics/hot.json" parameters:nil succeess:^(NSURLSessionDataTask * _Nonnull task, NSDictionary * _Nonnull responseObject) {
        
    } failure:^(NSURLSessionDataTask * _Nonnull task, NSError * _Nonnull error) {
        
    }] ;
    
    [SINetworkManager networkStatusChageWithBlock:^(SINetworkStatusType status) {
        NSLog(@"%ld",status) ;
    }];
}

- (void)networkStatusChange {
    // NSLog(@"当前网络状态：%ld",[SINetworkManager networkStatusType]);
}


@end
