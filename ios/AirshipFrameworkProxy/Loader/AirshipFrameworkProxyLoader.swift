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
        pluginLoader?.onLoad()
    }
}

