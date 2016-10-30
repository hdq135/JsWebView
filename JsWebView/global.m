//
//  global.m
//  JsWebView
//
//  Created by hdq on 16/10/29.
//  Copyright © 2016年 hdq. All rights reserved.
//

#import "global.h"
#import "JsBridge.h"

@implementation global

- (void)js_add:(NSNumber *)a b:(NSNumber *)b callback:(NSString *)callback{
    
   [[JsBridge global] callJs:[NSString stringWithFormat:@"%@(%ld)",callback,([a integerValue] + [b integerValue])] callback:^(id data) {
       NSLog(@"%@",data);
   }];
}

@end
