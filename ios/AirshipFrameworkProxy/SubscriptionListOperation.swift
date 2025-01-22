/* Copyright Airship and Contributors */

import Foundation

#if canImport(AirshipKit)
import AirshipKit
#elseif canImport(AirshipCore)
import AirshipCore
#endif

public struct SubscriptionListOperation: Decodable, Sendable {
    enum Action: String, Codable, Sendable {
        case subscribe
        case unsubscribe
    }

    let action: Action
    let listID: String

    private enum CodingKeys: String, CodingKey {
        case action = "action"
        case listID = "listId"
    }

    func apply(editor: SubscriptionListEditor) {
        switch(action) {
        case .subscribe:
            editor.subscribe(listID)
        case .unsubscribe:
            editor.unsubscribe(listID)
        }
    }
}
