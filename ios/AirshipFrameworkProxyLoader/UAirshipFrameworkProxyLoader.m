/* Copyright Airship and Contributors */

#import "UAirshipFrameworkProxyLoader.h"

#if __has_include("AirshipFrameworkProxy/AirshipFrameworkProxy-Swift.h")
#import <AirshipFrameworkProxy/AirshipFrameworkProxy-Swift.h>
#elif __has_include("AirshipFrameworkProxy-Swift.h")
#import "AirshipFrameworkProxy-Swift.h"
#else
@import AirshipFrameworkProxy;
#endif

@implementation UAirshipFrameworkProxyLoader

+ (void)load {
    [AirshipFrameworkProxyLoader onLoad];
}

@end

