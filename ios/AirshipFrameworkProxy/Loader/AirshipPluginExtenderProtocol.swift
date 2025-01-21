/* Copyright Airship and Contributors */

import Foundation

#if canImport(AirshipKit)
public import AirshipKit
#elseif canImport(AirshipCore)
public import AirshipCore
#endif

public protocol AirshipPluginExtenderProtocol: NSObject {
    @MainActor
    static func onAirshipReady()

    @MainActor
    static func extendConfig(config: AirshipConfig)
}

public extension AirshipPluginExtenderProtocol {
    static func extendConfig(config: AirshipConfig) {}
}
