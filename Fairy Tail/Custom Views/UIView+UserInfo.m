//
//  UIButton+UserInfo.m
//  YidioApp
//
//  Created by Simply Tech on 1/25/13.
//
//

#import "UIView+UserInfo.h"
#import <objc/runtime.h>

@implementation UIView (UserInfo)

static char UIB_USERINFO_KEY;

@dynamic userInfo;

- (void)setUserInfo:(NSDictionary *)userInfo
{
    objc_setAssociatedObject(self, &UIB_USERINFO_KEY, userInfo, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSDictionary *)userInfo
{
    return (NSDictionary*)objc_getAssociatedObject(self, &UIB_USERINFO_KEY);
}

@end
