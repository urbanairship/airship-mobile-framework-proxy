/* Copyright Airship and Contributors */

import Foundation

#if canImport(AirshipKit)
import AirshipKit
#elseif canImport(AirshipCore)
import AirshipCore
#endif

public protocol AirshipPluginExtenderProtocol: NSObject {
    @MainActor
    static func onAirshipReady()

    @MainActor
    static func extendConfig(config: AirshipConfig)
}


public extension AirshipPluginExtenderProtocol {
    static func extendConfig(config: AirshipConfig) {
    }
}


public class Thing: NSObject, AirshipPluginExtenderProtocol {
    public static func onAirshipReady() {

    }

    public static func extendConfig(config: AirshipConfig) {

    }

}
