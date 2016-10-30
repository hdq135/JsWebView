//
//  ViewController.m
//  JsWebView
//
//  Created by hdq on 16/10/29.
//  Copyright © 2016年 hdq. All rights reserved.
//

#import "ViewController.h"
#import "JSWebView.h"
#import "JsBridge.h"

@interface ViewController ()

@end

@implementation ViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    JSWebView *wv = [JSWebView create:self.view.frame];
    [JsBridge global].webview= wv;
    [self.view addSubview:wv];
    
    [wv loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://baidu.com"]]];
    

    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:@"test" forState:UIControlStateNormal];
    [button setFrame:CGRectMake(100, 100, 100, 100)];
    [button addTarget:self action:@selector(test:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];

}

- (void)test:(UIButton *)sender{
    
    [[JsBridge global] callJs:@"jsbridge.global.add(1,2,function(a){return a;})" deleteFunc:nil callback:nil];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
