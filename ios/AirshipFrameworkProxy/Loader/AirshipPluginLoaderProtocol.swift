/* Copyright Airship and Contributors */

public import UIKit

public protocol AirshipPluginLoaderProtocol: NSObject {
    @MainActor
    static func onLoad()
}

extension AirshipPluginLoaderProtocol {
    @MainActor
    public static func onLoad() {}
}

