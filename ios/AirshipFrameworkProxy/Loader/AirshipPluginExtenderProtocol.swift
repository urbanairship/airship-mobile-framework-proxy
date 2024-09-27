/* Copyright Airship and Contributors */

import UIKit

public protocol AirshipPluginExtenderProtocol: NSObject {
    @MainActor
    static func onAirshipReady()
}
