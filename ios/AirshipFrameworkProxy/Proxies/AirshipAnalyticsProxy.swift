/* Copyright Urban Airship and Contributors */

import Foundation

#if canImport(AirshipKit)
import AirshipKit
#elseif canImport(AirshipCore)
import AirshipCore
#endif

public final class AirshipAnalyticsProxy: Sendable {

    private let analyticsProvider: @Sendable () throws -> any AirshipAnalytics
    private var analytics: any AirshipAnalytics {
        get throws { try analyticsProvider() }
    }

    init(analyticsProvider: @Sendable  @escaping () throws -> any AirshipAnalytics) {
        self.analyticsProvider = analyticsProvider
    }

    public func addEvent(_ json: Any) throws {
        AirshipLogger.trace("addEvent called")
        guard
            let event = json as? [String: Any],
            let name = event["eventName"] as? String
        else {
            throw AirshipErrors.error("Invalid event: \(json)")
        }
        
        // Value
        var customEvent: CustomEvent = if let value = event["eventValue"] as? Double {
            CustomEvent(name: name, value: value)
        } else if let value = event["eventValue"] as? String, let double = Double(value) {
            CustomEvent(name: name, value: double)
        } else {
            CustomEvent(name: name)
        }
        
        if let properties = event["properties"] as? [String: Any] {
            try customEvent.setProperties(properties)
        }

        if let transactionID = event["transactionId"] as? String {
            customEvent.transactionID = transactionID
        }

        if let interactionID = event["interactionId"] as? String {
            customEvent.interactionID = interactionID
        }

        if let interactionType = event["interactionType"] as? String {
            customEvent.interactionType = interactionType
        }

        guard customEvent.isValid() else {
            throw AirshipErrors.error("Invalid event: \(event)")
        }
        
        try analytics.recordCustomEvent(customEvent)
    }

    @MainActor
    public func trackScreen(_ screen: String?) throws {
        AirshipLogger.trace("trackScreen called, screen=\(String(describing: screen))")
        try self.analytics.trackScreen(screen)
    }

    @MainActor
    public func getSessionID() throws -> String {
        AirshipLogger.trace("getSessionID called")
        return try self.analytics.sessionID
    }

    public func associateIdentifier(
        identifier: String?,
        key: String
    ) throws {
        AirshipLogger.trace("associateIdentifier called, key=\(key)")
        let identifiers = try self.analytics.currentAssociatedDeviceIdentifiers()
        identifiers.set(identifier: identifier, key: key)
        try self.analytics.associateDeviceIdentifiers(identifiers)
    }

}
