/* Copyright Airship and Contributors */

import Foundation

#if canImport(AirshipKit)
import AirshipKit
#elseif canImport(AirshipCore)
import AirshipCore
#endif

public struct TagOperation: Decodable, Equatable {
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

    func apply(editor: TagOperationEditor) {
        switch(action) {
        case .removeTags:
            editor.remove(tags)
        case .addTags:
            editor.add(tags)
        }
    }
}

protocol TagOperationEditor {
    func add(_ tags: [String])
    func remove(_ tags: [String])
}

extension TagEditor: TagOperationEditor {}
