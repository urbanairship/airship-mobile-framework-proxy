/* Copyright Urban Airship and Contributors */

import Foundation
import AirshipKit

public class AirshipLocaleProxy {

    private let localeProvider: () throws -> AirshipLocaleManagerProtocol
    private var locale: AirshipLocaleManagerProtocol {
        get throws { try localeProvider() }
    }

    init(localeProvider: @escaping () throws -> any AirshipLocaleManagerProtocol) {
        self.localeProvider = localeProvider
    }

    public func setCurrentLocale(_ localeIdentifier: String?) throws {
        if let localeIdentifier = localeIdentifier {
            try self.locale.currentLocale = Locale(
                identifier: localeIdentifier
            )
        } else {
            try self.locale.clearLocale()
        }

    }

    public func getCurrentLocale() throws -> String {
        return try self.locale.currentLocale.identifier
    }

    public func clearLocale() throws {
        try self.locale.clearLocale()
    }

}

