/* Copyright Urban Airship and Contributors */

import Foundation
import AirshipKit

@objc
public class AirshipAnalyticsProxy: NSObject {

    private let analyticsProvider: () throws -> AirshipAnalyticsProtocol
    private var analytics: AirshipAnalyticsProtocol {
        get throws { try analyticsProvider() }
    }

    init(analyticsProvider: @escaping () throws -> AirshipAnalyticsProtocol) {
        self.analyticsProvider = analyticsProvider
    }

    @objc
    public func addEvent(_ json: Any) throws {
        guard
            let event = json as? [String: Any],
            let name = event["eventName"] as? String
        else {
            throw AirshipErrors.error("Invalid event: \(json)")
        }
        
        // Value
        let customEvent: CustomEvent!
        if let value = event["eventValue"] as? NSNumber {
            customEvent = CustomEvent(name: name, value: value)
        } else  if let value = event["eventValue"] as? String {
            customEvent = CustomEvent(name: name, stringValue: value)
        } else {
            customEvent = CustomEvent(name: name)
        }
        
        if let properties = event["properties"] as? [String: Any] {
            customEvent.properties = properties
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
        
        try analytics.addCustomEvent(event: customEvent)
    }

    @objc
    public func trackScreen(_ screen: String?) throws {
        try self.analytics.trackScreen(screen)
    }

    @objc
    public func associateIdentifier(
        identifier: String?,
        key: String
    ) throws {
        try self.analytics.associateIdentifier(
            identifier: identifier,
            key: key
        )
    }

}

protocol AirshipAnalyticsProtocol: AnyObject {
    func trackScreen(_ screen: String?)
    func associateIdentifier(identifier: String?, key: String)
    func addCustomEvent(event: CustomEvent)

}

extension Analytics: AirshipAnalyticsProtocol {

    func associateIdentifier(identifier: String?, key: String) {
        let identifiers = self.currentAssociatedDeviceIdentifiers()
        identifiers.set(identifier: identifier, key: key)
        self.associateDeviceIdentifiers(identifiers)
    }
    
    func addCustomEvent(event: CustomEvent) {
        self.addEvent(event)
    }

}
