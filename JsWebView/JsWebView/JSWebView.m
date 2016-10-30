//
//  JSWebView.m
//  qixiubaov2
//
//  Created by hdq on 16/10/19.
//  Copyright © 2016年 nanxinwang. All rights reserved.
//

#import <objc/message.h>

#import "JSWebView.h"
#import "JsBridge.h"

@interface ScriptMessageHandler : NSObject<WKScriptMessageHandler>

@property (nullable, nonatomic, weak)id <WKScriptMessageHandler> delegate;

/** 创建方法 */
- (instancetype)initWithDelegate:(id <WKScriptMessageHandler>)delegate;

/** 便利构造器 */
+ (instancetype)scriptWithDelegate:(id <WKScriptMessageHandler>)delegate;;

@end


@interface JSWebView() <WKNavigationDelegate,WKScriptMessageHandler>
@end

@implementation JSWebView

+ (instancetype)create:(CGRect)frame{
    return [[self alloc] initWithFrame:frame];
}

- (WKWebViewConfiguration *)getConfiguration{
    WKUserContentController *user = [[WKUserContentController alloc] init];
    [user addScriptMessageHandler:[ScriptMessageHandler scriptWithDelegate:self] name:[JsBridge global].handlerName];
    
    WKUserScript *userScript = [[WKUserScript alloc] initWithSource:[[JsBridge global] getJsWith:@[NSClassFromString(@"global")]] injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:NO];
    
    [user addUserScript:userScript];
    
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    config.userContentController = user;
    return config;
}
- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame configuration:[self getConfiguration]];
    self.navigationDelegate = self;
    return self;
}

/**iOS 9以前不支持读取本地document目录下面的网页文件，这里做下处理**/
- (nullable WKNavigation *)loadRequest:(NSURLRequest *)request{
    if (!request.URL.fileURL) {
        return [super loadRequest:request];
    }
    NSLog(@"%@",[NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@",NSTemporaryDirectory(),[request.URL.absoluteString substringFromIndex:[request.URL.absoluteString rangeOfString:request.URL.lastPathComponent].location]]]);
    
    SEL sel = NSSelectorFromString(@"loadFileURL:allowingReadAccessToURL:");
    if([self respondsToSelector:sel]){
        return [super loadFileURL:request.URL allowingReadAccessToURL:[NSURL fileURLWithPath:request.URL.path]];
    }else{
        if ([request.URL.pathComponents count] <= 2) {
            return nil;
        }
        /*截取文件名和参数*/
        NSString *lastComponent = [request.URL.absoluteString substringFromIndex:[request.URL.absoluteString rangeOfString:request.URL.pathComponents[[request.URL.pathComponents count]-2]].location];
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@",NSTemporaryDirectory(),lastComponent]];
        NSURLRequest *r = [NSURLRequest requestWithURL:url];
        return [super loadRequest:r];
    }
}

- (void)setCookie:(NSDictionary *)dict{
    if (!self.URL.host) {
        return;
    }
    NSArray *oldCookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:self.URL];
    NSHTTPCookie *oldCookie = nil;
    if (oldCookies && oldCookies.count > 0) {
        oldCookie = oldCookies[0];
    }
    NSMutableDictionary *cookieInfo = [NSMutableDictionary dictionaryWithDictionary:oldCookie.properties];
    if (cookieInfo.count == 0){
        [cookieInfo setObject:@0 forKey:NSHTTPCookieVersion];
        [cookieInfo setObject:@"/" forKey:NSHTTPCookiePath];
        [cookieInfo setObject:self.URL.host forKey:NSHTTPCookieDomain];
    }
    for (NSString *key in [dict allKeys]) {
        [cookieInfo setObject:key forKey:NSHTTPCookieName];
        [cookieInfo setObject:dict[key] forKey:NSHTTPCookieValue];
        NSHTTPCookie * userCookie = [NSHTTPCookie cookieWithProperties:cookieInfo];
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:userCookie];
    }
    
}

#pragma mark - WKNavigationDelegate
- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
}

- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation {
    
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error{
    if ([error code] != NSURLErrorCancelled) {
        //show error alert, etc.
        [[[UIAlertView alloc] initWithTitle:@"错误" message:@"网络出现问题了" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"重试", nil] show];
    }
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler{
    WKNavigationActionPolicy isAllow = WKNavigationActionPolicyAllow;
//    if (navigationAction.targetFrame.request != nil) {
//        NSURL *url = navigationAction.targetFrame.request.URL;
//        isAllow = WKNavigationActionPolicyCancel;
//    }
    decisionHandler(isAllow);
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error{
    [[[UIAlertView alloc] initWithTitle:@"错误" message:@"网络出现问题了" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"重试", nil] show];
}

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message{
    
    if (![message.body isKindOfClass:[NSDictionary class]]) {
        return;
    }
    NSString *className = message.body[@"module"];
    NSString *func = message.body[@"func"];
    NSArray *param = message.body[@"param"];
    
    id module = [[JsBridge global] getModule:className];
    if (module) {
        if (param == nil) {
            ((void (*) (id, SEL)) objc_msgSend)(module,NSSelectorFromString(func));
        }else{
            switch (param.count) {
                case 1:
                    ((void (*) (id, SEL, id)) objc_msgSend) (module, NSSelectorFromString(func), param[0]);
                    break;
                case 2:
                    ((void (*) (id, SEL, id,id)) objc_msgSend) (module, NSSelectorFromString(func), param[0], param[1]);
                    break;
                case 3:
                    ((void (*) (id, SEL, id,id,id)) objc_msgSend) (module, NSSelectorFromString(func), param[0], param[1], param[2]);
                    break;
                    
                default:
                    NSAssert(0, @"error func");
                    break;
            }
        }
    }
    
}


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex == alertView.cancelButtonIndex) {
        return;
    }
    [self reload];
}
@end


@implementation ScriptMessageHandler

+(instancetype)scriptWithDelegate:(id<WKScriptMessageHandler>)delegate
{
    return [[ScriptMessageHandler alloc]initWithDelegate:delegate];
}

-(instancetype)initWithDelegate:(id<WKScriptMessageHandler>)delegate
{
    if (self = [super init])
    {
        _delegate = delegate;
    }
    
    return self;
}



#pragma mark - <WKScriptMessageHandler>
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
{
    [self.delegate userContentController:userContentController didReceiveScriptMessage:message];
}

@end


