/* Copyright Airship and Contributors */

import UIKit

public protocol AirshipPluginLoaderProtocol: NSObject {
    @MainActor
    static func onLoad()
    @MainActor
    static func onApplicationDidFinishLaunching(launchOptions: [UIApplication.LaunchOptionsKey : Any]?)
}

extension AirshipPluginLoaderProtocol {
    @MainActor
    public static func onLoad() {}
}

