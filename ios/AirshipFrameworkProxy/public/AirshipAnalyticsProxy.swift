/* Copyright Urban Airship and Contributors */

import Foundation
import AirshipKit

public class AirshipAnalyticsProxy {

    private let analyticsProvider: () throws -> AirshipAnalyticsProtocol
    private var analytics: AirshipAnalyticsProtocol {
        get throws { try analyticsProvider() }
    }

    init(analyticsProvider: @escaping () throws -> AirshipAnalyticsProtocol) {
        self.analyticsProvider = analyticsProvider
    }



    public func trackScreen(_ screen: String) throws {
        try self.analytics.trackScreen(screen)
    }



    public func associateIdentifier(
        identifier:String,
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
}

extension Analytics: AirshipAnalyticsProtocol {

    func associateIdentifier(identifier: String?, key: String) {
        let identifiers = self.currentAssociatedDeviceIdentifiers()
        identifiers.set(identifier: identifier, key: key)
        self.associateDeviceIdentifiers(identifiers)
    }


}
