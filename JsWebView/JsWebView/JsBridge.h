//
//  JsBridge.h
//  qixiubaov2
//
//  Created by hdq on 15/12/3.
//  Copyright © 2015年 nanxinwang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

@interface JsBridge : NSObject

@property (weak, nonatomic) WKWebView *webview;

@property (strong , nonatomic) NSString *handlerName;

+ (instancetype)global;


/**
 返回需要注入的js代码

 @param modules 数组，存放需要注入的对象类名

 @return 返回需要注入的js代码
 */
- (NSString *)getJsWith:(NSArray<Class> *)modules;
/** 根据moduleName获取接口 module 对象 **/
- (id)getModule:(NSString *)moduleName;

- (NSString *)ObjectToJsonStr:(NSObject *)obj;


/**
 原生函数调用执行js代码接口 执行后默认删除执行的js脚本

 @param js    js代码字串
 @param block js执行后返回值回调，如果执行后有返回值则在回调里面的data里面获取。
 */
- (void)callJs:(NSString *)js callback:(void(^)(id data))block;

/**
 原生函数调用执行js代码接口
 
 @param js    js代码字串
 @param funcName 要删除的js函数名，为空则不删除
 @param block js执行后返回值回调，如果执行后有返回值则在回调里面的data里面获取。
 */
- (void)callJs:(NSString *)js deleteFunc:(NSString *)funcName callback:(void (^)(id))block;
@end
