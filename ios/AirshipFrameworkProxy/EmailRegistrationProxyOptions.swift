/* Copyright Airship and Contributors */

import Foundation

#if canImport(AirshipKit)
import AirshipKit
#elseif canImport(AirshipCore)
import AirshipCore
#endif

public struct EmailRegistrationProxyOptions: Decodable, Sendable {
    let transactionalOptedInMilliseconds: Double?
    let commercialOptedInMilliseconds: Double?
    let properties: [String: String]?
    let doubleOptIn: Bool

    private enum CodingKeys: String, CodingKey {
        case transactionalOptedInMilliseconds = "transactionalOptedIn"
        case commercialOptedInMilliseconds = "commercialOptedIn"
        case properties
        case doubleOptIn
    }

    func toEmailRegistrationOptions() -> EmailRegistrationOptions {
        let transactionalDate = transactionalOptedInMilliseconds.map {
            Date(timeIntervalSince1970: $0 / 1000.0)
        }
        let commercialDate = commercialOptedInMilliseconds.map {
            Date(timeIntervalSince1970: $0 / 1000.0)
        }

        if commercialDate != nil {
            return EmailRegistrationOptions.commercialOptions(
                transactionalOptedIn: transactionalDate,
                commercialOptedIn: commercialDate,
                properties: properties
            )
        } else {
            return EmailRegistrationOptions.options(
                transactionalOptedIn: transactionalDate,
                properties: properties,
                doubleOptIn: doubleOptIn
            )
        }
    }
}
