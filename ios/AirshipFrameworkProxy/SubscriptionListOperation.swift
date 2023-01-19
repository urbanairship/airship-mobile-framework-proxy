/* Copyright Airship and Contributors */

import Foundation
import AirshipKit

public struct SubscriptionListOperation: Decodable {
    enum Action: String, Codable {
        case subscribe
        case unsubscribe
    }

    let action: Action
    let listID: String

    private enum CodingKeys: String, CodingKey {
        case action = "type"
        case listID = "listId"
    }

    func apply(editor: SubscriptionListEditor) {
        guard listID.isEmpty else {
            AirshipLogger.error("Invalid subscription list operation: \(self)")
            return
        }

        switch(action) {
        case .subscribe:
            editor.subscribe(listID)
        case .unsubscribe:
            editor.unsubscribe(listID)
        }
    }
}
