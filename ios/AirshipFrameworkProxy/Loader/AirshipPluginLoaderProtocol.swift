/* Copyright Airship and Contributors */

import UIKit

public protocol AirshipPluginLoaderProtocol: NSObject {
    @MainActor
    static func onApplicationDidFinishLaunching(launchOptions: [UIApplication.LaunchOptionsKey : Any]?)
}
