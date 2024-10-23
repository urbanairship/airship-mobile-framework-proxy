/* Copyright Urban Airship and Contributors */

import Foundation

#if canImport(AirshipKit)
import AirshipKit
#elseif canImport(AirshipCore)
import AirshipCore
#endif

/// Plugin forward delegates
@MainActor
public class AirshipPluginForwardDelegates {
    /// Shared instance
    public static let shared: AirshipPluginForwardDelegates = AirshipPluginForwardDelegates()

    /// Deep link delegate
    public var deepLinkDelegate: AirshipPluginDeepLinkDelegate?

    /// Push notification delegate.
    /// Note:  Implementing `extendPresentationOptions(_:notification:completionHandler:)`
    /// will break handling of request options per notification in plugins that support that feature.
    public var pushNotificationDelegate: PushNotificationDelegate?

    /// Registration delegate
    public var registrationDelegate: RegistrationDelegate?

    private init() {}
}

public protocol AirshipPluginDeepLinkDelegate {

    /// Called when a deep link has been triggered from Airship. If implemented, the delegate is responsible for processing the provided url.
    /// - Parameters:
    ///     - deepLink: The deep link.
    /// - Returns: true if the deep link was handled, otherwise false.
    @MainActor
    func receivedDeepLink(_ deepLink: URL) async -> Bool
}

