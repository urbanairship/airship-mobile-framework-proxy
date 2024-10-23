/* Copyright Airship and Contributors */

import UIKit

#if canImport(AirshipKit)
import AirshipKit
#elseif canImport(AirshipCore)
import AirshipCore
#endif

@objc
@MainActor
public class AirshipFrameworkProxyLoader: NSObject {
    private static let pluginLoader: AirshipPluginLoaderProtocol.Type? = {
        NSClassFromString("AirshipPluginLoader") as? AirshipPluginLoaderProtocol.Type
    }()

    @objc
    public static func onLoad() {
        pluginLoader?.onLoad()
    }

    @objc
    public static func onApplicationDidFinishLaunching(launchOptions: [UIApplication.LaunchOptionsKey : Any]?) {
        pluginLoader?.onApplicationDidFinishLaunching(launchOptions: launchOptions)
    }
}

