/* Copyright Urban Airship and Contributors */

import Foundation
import AirshipKit

@objc
public class AirshipLocaleProxy: NSObject {

    private let localeProvider: () throws -> AirshipLocaleProtocol
    private var locale: AirshipLocaleProtocol {
        get throws { try localeProvider() }
    }

    init(localeProvider: @escaping () throws -> any AirshipLocaleProtocol) {
        self.localeProvider = localeProvider
    }

    @objc
    public func setCurrentLocale(_ localeIdentifier: String) throws {
        try self.locale.currentLocale = Locale(
            identifier: localeIdentifier
        )
    }

    @objc
    public func getCurrentLocale() throws -> String {
        return try self.locale.currentLocale.identifier
    }

    @objc
    public func clearLocale() throws {
        try self.locale.clearLocale()
    }

}

protocol AirshipLocaleProtocol: AnyObject {
    func clearLocale()
    var currentLocale: Locale { get set }
}

extension LocaleManager: AirshipLocaleProtocol {
    
}
