//
//  NSString+OCClassToJsClass.m
//  WKWebviewTest
//
//  Created by hdq on 16/10/20.
//  Copyright © 2016年 mirroon. All rights reserved.
//

#import "JsFromOCClass.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import "ViewController.h"
#import "JsBridge.h"


@interface JsFromOCClass ()

@end

@implementation JsFromOCClass

+ (instancetype)create:(Class)class{
    return [[self alloc] initWithClass:class];
}

- (instancetype)initWithClass:(Class)class{
    self = [self init];

    _jsInterface = [[class alloc] init];
    NSDictionary *dict = [self checkClass:class];
    NSString *JSInitStr = dict[@"JSInitStr"];
    if (JSInitStr != nil && ![JSInitStr isEqualToString:@""]) {
        
        NSString *postMsg = @"";
        
        if ([_jsInterface respondsToSelector:NSSelectorFromString(@"jsinitDone:")]) {
            postMsg = [[NSString stringWithFormat:@"window.webkit.messageHandlers.%@.postMessage",[JsBridge global].handlerName] stringByAppendingString: @"({\"module\":\"%@\",\"func\":\"jsinitDone:\",\"param\":[data]});"];
            postMsg = [NSString stringWithFormat:postMsg,[class description],postMsg];
        }
        
        _jsInitStr =  [NSString stringWithFormat:@"(function(){%@;%@})();",JSInitStr,postMsg];
    }
    if ([dict.allKeys containsObject:@"JSStr"]) {
        _jsBodyStr = dict[@"JSStr"];
        
    }else{
        NSDictionary *dict = [self instanceMethods:class];
        NSArray *result = [self jsClassWithDict:dict];
        if (result.count >0) {
            _jsBodyStr = result[0];
        }
    }
    return self;
}
- (NSDictionary *)checkClass:(Class)class{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    unsigned int outCount;
    Method *methods = class_copyMethodList(object_getClass(class), &outCount);
    
    for (int i = 0; i < outCount; i++) {
        NSString *funcName = NSStringFromSelector(method_getName(methods[i]));
        if([funcName isEqualToString:@"getJsInitString"]){
            dict[@"JSInitStr"] = ((id (*) (id, SEL)) objc_msgSend) (class, NSSelectorFromString(@"getJsInitString"));
        }else if ([funcName isEqualToString:@"getJsString"]) {
            NSString *js = ((id (*) (id, SEL)) objc_msgSend) (class, NSSelectorFromString(@"getJsString"));
            NSString *postMsg = [NSString stringWithFormat:@"window.webkit.messageHandlers.%@.postMessage",[JsBridge global].handlerName];
            dict[@"JSStr"] = [NSString stringWithFormat:js,postMsg,postMsg,postMsg];
        }
    }
    free(methods);
    return dict;
}

- (NSDictionary *)instanceMethods:(Class)class{
    unsigned int outCount;
    Method *methods = class_copyMethodList(class, &outCount);
    NSMutableArray *result = [NSMutableArray array];
    NSString *jsHeader = @"js_";
    
    for (int i = 0; i < outCount; i++) {
        NSString *funcName = NSStringFromSelector(method_getName(methods[i]));
        if (![funcName hasPrefix:jsHeader]) {
            continue;
        }else{
            funcName = [funcName substringFromIndex:jsHeader.length];
        }
        
        NSInteger args = method_getNumberOfArguments(methods[i]) - 2;
        [result addObject:@{@"func":funcName,@"args":@(args)}];
    }
    free(methods);
    if (result.count > 0) {
        return @{[class description]:[result copy]};
    }
    return nil;
}

- (NSArray *)jsClassWithDict:(NSDictionary *)dict{
    NSMutableArray *modules = [NSMutableArray array];
    for (NSString *moduleName in dict.allKeys) {
        NSString *module = [self jsClassModule:moduleName funcs:dict[moduleName]];
        if (module != nil && ![module isEqualToString:@""]) {
            [modules addObject:module];
        }
    }
    return modules;
}

- (NSString *)jsClassModule:(NSString *)moduleName funcs:(NSArray *)funcs{
    
    NSMutableString *str = [NSMutableString string];
    [str appendFormat:@"%@:{",moduleName];
    for (NSDictionary *func in funcs) {
        NSString *f = [self jsClassfuncWith:moduleName func:func[@"func"] args:[func[@"args"] integerValue]];
        if (f != nil && ![f isEqualToString:@""]) {
            [str appendFormat:@"%@,",f];
        }
    }
    /*删除多余逗号*/
    if ([str hasSuffix:@","]) {
        [str deleteCharactersInRange:NSMakeRange(str.length-1, 1)];
    }
    [str appendString:@"}"];
    return str;
}


- (NSString *)jsClassfuncWith:(NSString *)moduleName func:(NSString *)func args:(NSInteger)args{
    if (func == nil || [func isEqualToString:@""]) {
        return nil;
    }
    NSMutableString *str = [NSMutableString string];
    NSArray *arr = [func componentsSeparatedByString:@":"];
    //给js函数用的参数。
    NSMutableString *paramStr = [NSMutableString string];
    //js传给oc函数的参数。
    NSMutableString *paramStrForOC = [NSMutableString string];
    [paramStrForOC appendString:@",\"param\":["];
    /**
     判断参数是否闭包，如果是则存储闭包至 window.QXBTEMPFUNC[参数名＋时间戳] ，然后作为字串传给原生接口调用。
      v1 整型 输入参数标号，确定是第几个参数。
      v2 字串 参数名字。
      v3 字串 参数名字。
      v4 整型 输入参数标号，确定是第几个参数。
      v5 字串 参数名字
      v6 整型 输入参数标号，确定是第几个参数。
      v7 字串 参数名字
      v8 整型 输入参数标号，确定是第几个参数。
      v9 整型 输入参数标号，确定是第几个参数。
    */
    NSString *closure = @"var var%d = %@; \
if(typeof %@ == \"function\") { \
    var tempFunc%d = \"%@\"+(new Date().getTime()); \
    window.QXBTEMPFUNC={}; \
    window.QXBTEMPFUNC[tempFunc%d] = %@; \
    var%d = \"window.QXBTEMPFUNC.\"+tempFunc%d; \
}";
    NSString *postMsg = [[NSString stringWithFormat:@"window.webkit.messageHandlers.%@.postMessage",[JsBridge global].handlerName] stringByAppendingString: @"({\"module\":\"%@\",\"func\":\"js_%@\"%@});"];

    NSMutableString *action = [NSMutableString string];
    for (int i=0;i<args;i++) {
        NSString *var = [NSString stringWithFormat:@"v%d",i];
        [paramStr appendFormat:@"%@,",var];
        [action appendString:[NSString stringWithFormat:closure,i,var,var,i,var,i,var,i,i]];
        [paramStrForOC appendFormat:@"var%d,",i];
    }
    /*删除多余逗号*/
    if ([paramStr hasSuffix:@","]) {
        [paramStr deleteCharactersInRange:NSMakeRange(paramStr.length-1, 1)];
    }
    /*删除多余逗号*/
    if ([paramStrForOC hasSuffix:@","]) {
        [paramStrForOC deleteCharactersInRange:NSMakeRange(paramStrForOC.length-1, 1)];
    }
    [paramStrForOC appendString:@"]"];
    //如果参数为空则不传。
    if ([paramStrForOC isEqualToString:@",\"param\":[]"]) {
        paramStrForOC = [NSMutableString string];
    }
    
    
    [str appendFormat:@"%@: function(%@){",arr[0],paramStr];
    [str appendString:action];
    [str appendFormat:postMsg,moduleName,func,paramStrForOC];
    
    [str appendFormat:@"}"];
    return str;
}

@end
