/* Copyright Airship and Contributors */

#import "UAirshipFrameworkProxyLoader.h"

#if __has_include("AirshipFrameworkProxy/AirshipFrameworkProxy-Swift.h")
#import <AirshipFrameworkProxy/AirshipFrameworkProxy-Swift.h>
#elif __has_include("AirshipFrameworkProxy-Swift.h")
#import "AirshipFrameworkProxy-Swift.h"
#else
@import AirshipFrameworkProxyBase;
#endif

@implementation UAirshipFrameworkProxyLoader

+ (void)load {
    [AirshipFrameworkProxyLoader onLoad];

    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserverForName:UIApplicationDidFinishLaunchingNotification
                        object:nil
                         queue:nil usingBlock:^(NSNotification * _Nonnull note) {

        [AirshipFrameworkProxyLoader onApplicationDidFinishLaunchingWithLaunchOptions:note.userInfo];
    }];
}

@end

