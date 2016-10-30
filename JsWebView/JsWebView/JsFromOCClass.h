//
//  NSString+OCClassToJsClass.h
//  WKWebviewTest
//
//  Created by hdq on 16/10/20.
//  Copyright © 2016年 mirroon. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 转化oc原生代码接口为 js代码。会遍历oc代码的所有以 "js_" 开头的函数，翻译成js函数。
 另外预留关键方法：
    返回接口初始化js代码。会在注入的时候调用，用来初始化一些接口所需js环境，并在初始化完成后，判断接口是否实现了jsinitDone：方法，实现了则会调jsinitDone方法。
    注：该js代码里面可以看到一个名为 data 的对象，用来存储一些值，直接使用不用定义，用在回调jsinitDone时候传回给原生接口。
    + (NSString *)getJsInitString;
    
    接口自定义js代码。实现该方法后，不会自动生成js代码，使用该方法返回的js代码。
    + (NSString *)getJsString;
    js代码初始化完成后回调接口。
    - (void)jsinitDone:(id)data
 */
@interface JsFromOCClass : NSObject

/**存储接口对象需要初始化的js代码**/
@property (strong , nonatomic ,readonly) NSString *jsInitStr;

/**存储接口对象与js交互的js代码**/
@property (strong , nonatomic,readonly) NSString *jsBodyStr;

/** 存储接口对象 **/
@property (strong , nonatomic,readonly) id jsInterface;

+ (instancetype)create:(Class)class;
@end
