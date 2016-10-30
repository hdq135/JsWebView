//
//  jsBridge.m
//  qixiubaov2
//
//  Created by hdq on 15/12/3.
//  Copyright © 2015年 nanxinwang. All rights reserved.
//

#import "JsBridge.h"
#import "JsFromOCClass.h"


@interface JsBridge () {
    NSInteger imageCount;
    NSInteger eventCode;
}
@property (strong, nonatomic) NSMutableDictionary *dict;
@property (copy, nonatomic) void(^searchBarCallBack)(NSString *event);

@property (strong, nonatomic) NSMutableDictionary *modules;
@end

@implementation JsBridge

+ (instancetype)global {
    static id instance;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[[self class] alloc] init];
    });
    
    return instance;
}

- (instancetype)init{
    self = [super init];
    _dict = [NSMutableDictionary dictionary];
    _handlerName = @"HDQ";
    if (!_modules) {
        _modules = [NSMutableDictionary dictionary];
    }
    return self;
}

- (id)getModule:(NSString *)moduleName{
    return _modules[moduleName];
}

- (NSString *)getJsWith:(NSArray<Class> *)modules{
    NSMutableString *str = [NSMutableString string];
    NSMutableString *initStr = [NSMutableString string];
    for (Class class in modules) {
        JsFromOCClass *jsObj = [JsFromOCClass create:class];
        _modules[NSStringFromClass(class)] = jsObj.jsInterface;
        if (jsObj.jsInitStr != nil && ![jsObj.jsInitStr isEqualToString:@""]){
            [initStr appendFormat:@"%@",jsObj.jsInitStr];
        }
        [str appendFormat:@"%@,", jsObj.jsBodyStr];
    }
    /*删除多余逗号*/
    if ([str hasSuffix:@","]) {
        [str deleteCharactersInRange:NSMakeRange(str.length-1, 1)];
    }
    return [NSString stringWithFormat:@"(function(){var data = \"\";%@})(); var jsbridge={%@,system:\"iOS\"};",initStr,str];
}

- (void)callJs:(NSString *)js callback:(void(^)(id data))block{
    NSRange range = [js rangeOfString:@"("];
    if (range.location == NSNotFound) {
        NSAssert(0, @"error js func");
        return;
    }
    NSString *funcName = [js substringToIndex:range.location];
    [self callJs:js deleteFunc:funcName callback:block];
}

- (void)callJs:(NSString *)js deleteFunc:(NSString *)funcName callback:(void (^)(id))block{

    [_webview evaluateJavaScript:js completionHandler:^(id _Nullable data, NSError * _Nullable error) {
        NSLog(@"calljs return = %@",data);
        if (block) {
            block(error!=nil?nil:data);
        }
        if (funcName != nil && ![funcName isEqualToString:@""]) {
            [_webview evaluateJavaScript:[NSString stringWithFormat:@"delete %@",funcName] completionHandler:nil];
        }
    }];
}

-(UIColor *)setColorWithArr:(NSArray *)color{
    CGFloat alpha = 1;
    if (color.count > 3) {
        alpha = [color[3] floatValue];
    }
    return   [UIColor colorWithRed:[color[0] floatValue]/255.0 green:[color[1] floatValue]/255.0  blue:[color[2] floatValue]/255.0  alpha:alpha];
}



- (NSString *)ObjectToJsonStr:(NSObject *)obj{
    if (obj == nil) {
        return @"";
    }
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:obj
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:nil];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData
                                                 encoding:NSUTF8StringEncoding];
    return jsonString;
}



@end
