/* Copyright Airship and Contributors */

public import UIKit

#if canImport(AirshipKit)
import AirshipKit
#elseif canImport(AirshipCore)
import AirshipCore
#endif

@objc
@MainActor
public class AirshipFrameworkProxyLoader: NSObject {
    private static let pluginLoader: (any AirshipPluginLoaderProtocol.Type)? = {
        NSClassFromString("AirshipPluginLoader") as? any AirshipPluginLoaderProtocol.Type
    }()

    @objc
    public static func onLoad() {
        AirshipLogger.debug("Loader onLoad called")
        if pluginLoader != nil {
            AirshipLogger.debug("Plugin loader found, delegating onLoad")
        } else {
            AirshipLogger.debug("No plugin loader found")
        }
        pluginLoader?.onLoad()
    }
}

