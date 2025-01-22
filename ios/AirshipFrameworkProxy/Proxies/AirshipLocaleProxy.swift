/* Copyright Urban Airship and Contributors */

import Foundation

#if canImport(AirshipKit)
import AirshipKit
#elseif canImport(AirshipCore)
import AirshipCore
#endif

public final class AirshipLocaleProxy: Sendable {

    private let localeProvider: @Sendable () throws -> any AirshipLocaleManagerProtocol
    private var locale: any AirshipLocaleManagerProtocol {
        get throws { try localeProvider() }
    }

    init(localeProvider: @Sendable @escaping () throws -> any AirshipLocaleManagerProtocol) {
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

    public var currentLocale: String {
        get throws {
            return try self.locale.currentLocale.identifier
        }
    }

    public func clearLocale() throws {
        try self.locale.clearLocale()
    }

}

