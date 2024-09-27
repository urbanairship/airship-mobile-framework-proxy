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
    private static let pluginLoaderClass = "AirshipPluginLoader"
    private static let extenderClass = "AirshipPluginExtender"

    private static var pluginLoader: AirshipPluginLoaderProtocol?
    private static var extender: AirshipPluginExtenderProtocol?

    @objc
    public static func onLoad() {
        if let classFromString =  NSClassFromString(self.extenderClass) as? AirshipPluginExtenderProtocol.Type {
            Airship.onReady {
                classFromString.onAirshipReady()
            }
        }
    }

    @objc
    public static func onApplicationDidFinishLaunching(launchOptions: [UIApplication.LaunchOptionsKey : Any]?) {
        if let classFromString =  NSClassFromString(self.pluginLoaderClass) as? AirshipPluginLoaderProtocol.Type {
            classFromString.onApplicationDidFinishLaunching(launchOptions: launchOptions)
        }
    }
}

