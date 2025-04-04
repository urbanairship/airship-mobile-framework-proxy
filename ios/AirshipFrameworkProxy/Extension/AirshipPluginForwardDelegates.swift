/* Copyright Urban Airship and Contributors */

import Foundation

#if canImport(AirshipKit)
public import AirshipKit
#elseif canImport(AirshipCore)
public import AirshipCore
#endif

/// Plugin forward delegates. This class is deprecated and will be removed in a future version.
@MainActor
public final class AirshipPluginForwardDelegates {
    /// Shared instance
    public static let shared: AirshipPluginForwardDelegates = AirshipPluginForwardDelegates()

    let storage = Storage()

    /// Deep link delegate
    @available(*, deprecated, message: "Use AirshipPluginExtensions.onDeepLink instead.")
    public var deepLinkDelegate: (any AirshipPluginDeepLinkDelegate)? {
        get {
            storage.deepLinkDelegate
        }
        set {
            storage.deepLinkDelegate = newValue
        }
    }

    /// Push notification delegate.
    /// Note:  Implementing `extendPresentationOptions(_:notification:completionHandler:)`
    /// will break handling of request options per notification in plugins that support that feature.
    @available(*, deprecated, message: "Use AirshipPluginExtensions.pushNotificationForwardDelegate instead.")
    public var pushNotificationDelegate: (any PushNotificationDelegate)? {
        get {
            storage.pushNotificationDelegate
        }
        set {
            storage.pushNotificationDelegate = newValue
        }
    }

    /// Registration delegate
    @available(*, deprecated, message: "Use AirshipPluginExtensions.registrationForwardDelegate instead.")
    public var registrationDelegate: (any RegistrationDelegate)? {
        get {
            storage.registrationDelegate
        }
        set {
            storage.registrationDelegate = newValue
        }
    }

    private init() {}

    // Used to avoid deprecation warnings from bubbling up
    @MainActor
    final class Storage {
        var deepLinkDelegate: (any AirshipPluginDeepLinkDelegate)?
        var pushNotificationDelegate: (any PushNotificationDelegate)?
        var registrationDelegate: (any RegistrationDelegate)?
    }
}

public protocol AirshipPluginDeepLinkDelegate {

    /// Called when a deep link has been triggered from Airship. If implemented, the delegate is responsible for processing the provided url.
    /// - Parameters:
    ///     - deepLink: The deep link.
    /// - Returns: true if the deep link was handled, otherwise false.
    @MainActor
    func receivedDeepLink(_ deepLink: URL) async -> Bool
}
