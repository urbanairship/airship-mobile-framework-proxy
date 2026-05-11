/* Copyright Airship and Contributors */

import Foundation

#if canImport(AirshipKit)
import AirshipKit
#elseif canImport(AirshipCore)
import AirshipCore
#endif

public struct SMSRegistrationProxyOptions: Decodable, Sendable {
    let senderID: String

    private enum CodingKeys: String, CodingKey {
        case senderID = "senderId"
    }

    func toSMSRegistrationOptions() -> SMSRegistrationOptions {
        return SMSRegistrationOptions.optIn(senderID: senderID)
    }
}
