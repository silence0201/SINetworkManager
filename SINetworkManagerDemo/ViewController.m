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
    [SINetworkManager setResponseSerializer:SIResponseSerializerXML] ;
    [SINetworkManager GET:@"http://www.w3school.com.cn/example/xmle/note.xml" parameters:nil succeess:^(NSURLSessionTask * _Nonnull task, NSDictionary * _Nonnull responseObject) {
    } failure:^(NSURLSessionTask * _Nonnull task, NSError * _Nonnull error) {
        
    }] ;

}

- (void)networkStatusChange {
    // NSLog(@"当前网络状态：%ld",[SINetworkManager networkStatusType]);
}


@end
