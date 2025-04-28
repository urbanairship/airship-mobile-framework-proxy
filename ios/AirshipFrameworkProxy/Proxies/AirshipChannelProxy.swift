/* Copyright Urban Airship and Contributors */

import Foundation

#if canImport(AirshipKit)
import AirshipKit
#elseif canImport(AirshipCore)
import AirshipCore
#endif

public final class AirshipChannelProxy: Sendable {
    private let channelProvider: @Sendable () throws -> any AirshipChannelProtocol
    private var channel: any AirshipChannelProtocol {
        get throws { try channelProvider() }
    }

    init(channelProvider: @Sendable @escaping () throws -> any AirshipChannelProtocol) {
        self.channelProvider = channelProvider
    }

    public func enableChannelCreation() throws -> Void {
        try self.channel.enableChannelCreation()
    }

    public func addTags(_ tags: [String]) throws {
        try self.channel.editTags { editor in
            editor.add(tags)
        }
    }

    public func removeTags(_ tags: [String]) throws {
        try self.channel.editTags { editor in
            editor.remove(tags)
        }
    }

    public func editTags(operations: [TagOperation]) throws {
        try self.channel.editTags { editor in
            operations.forEach { operation in
                operation.apply(editor: editor)
            }
        }
    }

    public var tags: [String] {
        get throws {
            return try self.channel.tags
        }
    }

    public func fetchSubscriptionLists() async throws -> [String] {
        return try await self.channel.fetchSubscriptionLists()
    }

    public var channelID: String? {
        get throws {
            return try self.channel.identifier
        }
    }

    public func waitForChannelID() async throws -> String {
        if let channelID = try self.channel.identifier {
            return channelID
        }

        for await update in try self.channel.identifierUpdates {
            return update
        }

        throw AirshipErrors.error("Failed to wait for Channel ID")
    }

    public func editTagGroups(operations: [TagGroupOperation]) throws {
        try self.channel.editTagGroups { editor in
            operations.forEach { operation in
                operation.apply(editor: editor)
            }
        }
    }

    public func editAttributes(operations: [AttributeOperation]) throws {
        let editor = try self.channel.editAttributes()
        try operations.forEach { operation in
            try operation.apply(editor: editor)
        }
        editor.apply()
    }

    public func editSubscriptionLists(json: Any) throws {
        let data = try AirshipJSONUtils.data(json)
        let operations = try JSONDecoder().decode(
            [SubscriptionListOperation].self,
            from: data
        )

        try self.editSubscriptionLists(operations: operations)
    }

    public func editSubscriptionLists(
        operations: [SubscriptionListOperation]
    ) throws {
        try self.channel.editSubscriptionLists { editor in
            operations.forEach { operation in
                operation.apply(editor: editor)
            }
        }
    }
}

