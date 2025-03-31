/* Copyright Urban Airship and Contributors */

import Foundation

#if canImport(AirshipKit)
public import AirshipKit
#elseif canImport(AirshipCore)
public import AirshipCore
#endif

/// A class that manages hooks for extending and overriding functionality in plugin-based frameworks.
///
/// The `AirshipPluginExtensions` class provides hooks (closures and delegates) that allow hybrid apps or plugin developers
/// to customize or override default behavior in the underlying native SDK. These hooks allow apps built with frameworks
/// like React Native, Cordova, Capacitor, and Flutter to customize certain behaviors without breaking the base plugin.
///
@MainActor
public final class AirshipPluginExtensions {

    /// Shared singleton instance of `AirshipPluginExtensions`.
    public static let shared: AirshipPluginExtensions = AirshipPluginExtensions()

    /// A closure that allows overriding the deep link handling functionality.
    ///
    /// Hybrid apps or plugins can use this closure to override the default behavior when a deep link is received.
    /// The closure receives a `URL` as input and returns an `AirshipPluginOverride<Void>`, which can either indicate
    /// that the default deep link handling should occur or that the app/plugin wants to perform custom handling.
    ///
    /// Developers should be cautious when overriding this hook, as it can interfere with the base plugin's deep link handling.
    ///
    /// - Parameter url: The `URL` to be handled.
    /// - Returns: An `AirshipPluginOverride<Void>` that specifies whether to handle the deep link or use the default behavior.
    public var onDeepLink: (@MainActor (URL) async -> AirshipPluginOverride<Void>)?

    /// A closure that allows overriding the notification presentation behavior when a push notification is received in the foreground.
    ///
    /// This closure is invoked when a notification is about to be presented in the foreground. It allows developers to
    /// override the default notification presentation options, such as modifying how the notification is displayed.
    /// It receives a `UNNotification` as input and returns an `AirshipPluginOverride<UNNotificationPresentationOptions>`,
    /// which defines how the notification should be presented.
    ///
    /// Developers should be mindful that overriding this hook can interfere with the base plugin’s notification behavior.
    ///
    /// - Parameter notification: The `UNNotification` that is about to be presented.
    /// - Returns: An `AirshipPluginOverride<UNNotificationPresentationOptions>` specifying how to present the notification.
    public var onWillPresentForegroundNotification: (@MainActor (UNNotification) async -> AirshipPluginOverride<UNNotificationPresentationOptions>)?

    /// A delegate for forwarding push notification events.
    public var pushNotificationForwardDelegate: (any AirshipPluginPushNotificationDelegate)?

    /// A delegate for forwarding device registration events.
    public var registrationForwardDelegate: (any RegistrationDelegate)?

    private init() {}
}

/// Airship push notification delegate without `extendPresentationOptions` method.
public protocol AirshipPluginPushNotificationDelegate: AnyObject, Sendable {
    /// Called when a notification is received in the foreground.
    ///
    /// - Parameters:
    ///   - userInfo: The notification info
    @MainActor
    func receivedForegroundNotification(_ userInfo: [AnyHashable: Any]) async
    #if !os(watchOS)
    /// Called when a notification is received in the background.
    ///
    /// - Parameters:
    ///   - userInfo: The notification info
    @MainActor
    func receivedBackgroundNotification(_ userInfo: [AnyHashable: Any]) async -> UIBackgroundFetchResult
    #else
    /// Called when a notification is received in the background.
    ///
    /// - Parameters:
    ///   - userInfo: The notification info
    @MainActor
    func receivedBackgroundNotification(_ userInfo: [AnyHashable: Any]) async -> WKBackgroundFetchResult
    #endif
    #if !os(tvOS)
    /// Called when a notification is received in the background or foreground and results in a user interaction.
    /// User interactions can include launching the application from the push, or using an interactive control on the notification interface
    /// such as a button or text field.
    ///
    /// - Parameters:
    ///   - notificationResponse: UNNotificationResponse object representing the user's response
    /// to the notification and the associated notification contents.
    @MainActor
    func receivedNotificationResponse(_ notificationResponse: UNNotificationResponse) async
    #endif
}

/// A generic enum used to optionally override functionality in the plugin.
///
/// This enum provides two possible states:
/// - `override(T)`: Indicates that a custom value of type `T` is being provided to override the default behavior.
/// - `useDefault`: Indicates that the default behavior should be used (no custom value is provided).
///
/// The enum conforms to the `Sendable` protocol, meaning it can be safely passed across concurrency domains (e.g., across threads).
///
/// - Parameter T: The type of the custom value used to override the default behavior. This value must conform to `Sendable` to ensure thread-safety.
public enum AirshipPluginOverride<T: Sendable>: Sendable {
    /// A case indicating that the functionality is being overridden with a custom value of type `T`.
    case override(T)

    /// A case indicating that the default functionality should be used, with no custom value.
    case useDefault
}

extension AirshipPluginOverride where T == Void {
    /// A static property that provides a default `.override` case when `T` is `Void`.
    ///
    /// When the type `T` is `Void`, this property can be used to represent the `override` case without any associated value.
    /// This is particularly useful when you want to override functionality without needing to pass any specific data.
    ///
    /// Example usage:
    /// ```
    /// let overridePlugin: AirshipPluginOverride<Void> = .override
    /// ```
    static var `override`: AirshipPluginOverride {
        .override(())
    }
}
