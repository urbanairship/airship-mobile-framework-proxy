/* Copyright Airship and Contributors */

import Foundation
import AirshipKit

public struct TagGroupOperation: Decodable {
    enum Action: String, Codable {
        case setTags = "set"
        case removeTags = "remove"
        case addTags = "add"
    }

    let action: Action
    let tags: [String]
    let group: String

    private enum CodingKeys: String, CodingKey {
        case group = "group"
        case action = "operationType"
        case tags = "tags"
    }

    func apply(editor: TagGroupsEditor) {
        guard group.isEmpty else {
            AirshipLogger.error("Invalid tag group operation: \(self)")
            return
        }

        switch(action) {
        case .removeTags:
            editor.remove(tags, group: group)
        case .setTags:
            editor.set(tags, group: group)
        case .addTags:
            editor.add(tags, group: group)
        }
    }
}
