/* Copyright Airship and Contributors */

import Foundation

#if canImport(AirshipKit)
public import AirshipKit
#elseif canImport(AirshipCore)
public import AirshipCore
#endif

/// A protocol that defines methods for customizing the initialization and behavior of the Airship SDK.
///
/// The `AirshipPluginExtenderProtocol` is intended to be adopted by apps or plugins that wish to customize how
/// the Airship SDK is initialized and to provide additional setup tasks once the SDK is ready. By conforming to this
/// protocol, developers can modify the Airship configuration, perform initialization logic, and extend the SDK’s
/// behavior when it’s ready to be used.
///
/// This protocol is specifically designed for **extending Airship's initialization process** and should be implemented
/// by a class exposed to Objective-C with the specific name `AirshipPluginExtender` to ensure that the plugin can
/// locate and use it during initialization.
///
/// - Note: The methods in this protocol are executed on the main thread using the `@MainActor` attribute to ensure
///         thread safety when interacting with UI elements or performing actions requiring main-thread execution.
public protocol AirshipPluginExtenderProtocol: NSObject {

    /// Called when the Airship SDK is ready for use.
    ///
    /// This method is invoked when the Airship SDK has finished initializing and is ready for further use. It is
    /// typically used for performing additional tasks that need to happen once Airship is fully initialized, such
    /// as triggering other parts of the app or configuring settings that rely on the SDK.
    ///
    /// This method is the best place to set up extensions or modifications to the behavior of the Airship SDK via
    /// the `AirshipPluginExtensions` class, ensuring that runtime customizations are applied before
    /// they are used.
    ///
    @MainActor
    static func onAirshipReady()

    /// A method to extend the Airship configuration before SDK initialization.
    ///
    /// This method allows developers to modify the configuration of the Airship SDK prior to its initialization.
    /// It provides a reference to the `AirshipConfig` object, allowing for custom configuration values to be set.
    ///
    /// - Parameter config: A mutable reference to the `AirshipConfig` object that can be modified.
    @MainActor
    static func extendConfig(config: inout AirshipConfig)
}

public extension AirshipPluginExtenderProtocol {
    static func extendConfig(config: inout AirshipConfig) {}
}
