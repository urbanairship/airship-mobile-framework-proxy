/* Copyright Airship and Contributors */

import Foundation
import AirshipKit

public struct ScopedSubscriptionListOperation: Decodable, Equatable {
    enum Action: String, Codable {
        case subscribe
        case unsubscribe
    }

    private let action: Action
    private let listID: String
    private let scope: ChannelScope

    init(action: Action, listID: String, scope: ChannelScope) {
        self.action = action
        self.listID = listID
        self.scope = scope
    }


    private enum CodingKeys: String, CodingKey {
        case action = "action"
        case listID = "listId"
        case scope = "scope"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.action = try container.decode(ScopedSubscriptionListOperation.Action.self, forKey: .action)
        self.listID = try container.decode(String.self, forKey: .listID)
        self.scope = try ChannelScope.fromString(container.decode(String.self, forKey: .scope))
    }

    func apply(editor: ScopedSubscriptionListEditor) throws {
        switch(action) {
        case .subscribe:
            editor.subscribe(listID, scope: scope)
        case .unsubscribe:
            editor.unsubscribe(listID, scope: scope)
        }
    }
}
