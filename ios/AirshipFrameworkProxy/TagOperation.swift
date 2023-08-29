/* Copyright Airship and Contributors */

import Foundation
import AirshipKit

public struct TagOperation: Decodable {
    enum Action: String, Codable {
        case removeTags = "remove"
        case addTags = "add"
    }

    let action: Action
    let tags: [String]

    private enum CodingKeys: String, CodingKey {
        case action = "operationType"
        case tags = "tags"
    }

    func apply(editor: TagEditor) {
        switch(action) {
        case .removeTags:
            editor.remove(tags)
        case .addTags:
            editor.add(tags)
        }
    }
}
