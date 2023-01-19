/* Copyright Airship and Contributors */

import Foundation
import AirshipKit

public struct ScopedSubscriptionListOperation: Decodable {
    enum Action: String, Codable {
        case subscribe
        case unsubscribe
    }

    let action: Action
    let listID: String
    let scope: String

    private enum CodingKeys: String, CodingKey {
        case action = "type"
        case listID = "listId"
        case scope = "scope"
    }

    func apply(editor: ScopedSubscriptionListEditor) {
        guard listID.isEmpty,
              let scope = try? ChannelScope.fromString(scope)
        else {
            AirshipLogger.error("Invalid subscription list operation: \(self)")
            return
        }

        switch(action) {
        case .subscribe:
            editor.subscribe(listID, scope: scope)
        case .unsubscribe:
            editor.unsubscribe(listID, scope: scope)
        }
    }
}
