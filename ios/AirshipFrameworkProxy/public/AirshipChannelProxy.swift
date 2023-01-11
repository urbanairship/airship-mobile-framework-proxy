/* Copyright Urban Airship and Contributors */

import Foundation
import AirshipKit

public class AirshipChannelProxy {
    private let channelProvider: () throws -> ChannelProtocol
    private var channel: ChannelProtocol {
        get throws { try channelProvider() }
    }

    init(channelProvider: @escaping () throws -> ChannelProtocol) {
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

    public func getTags() throws -> [String] {
        return try self.channel.tags
    }

    public func getSubscriptionLists() async throws -> [String] {
        let instance = try self.channel
        return try await withCheckedThrowingContinuation { continuation in
            instance.fetchSubscriptionLists { lists, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: lists ?? [])
            }
        }

    }

    public func getChannelId() throws -> String? {
        return try self.channel.identifier
    }

    public func editTagGroups(_ operations: Any) throws {
        let data = try JSONUtils.data(operations)
        let operations = try JSONDecoder().decode(
            [TagGroupOperation].self,
            from: data
        )
        try self.channel.editTagGroups { editor in
            operations.forEach { operation in
                operation.apply(editor: editor)
            }
        }
    }

    public func editAttributes(_ operations: Any) throws {
        let data = try JSONUtils.data(operations)
        let operations = try JSONDecoder().decode(
            [AttributeOperation].self,
            from: data
        )
        try self.channel.editAttributes { editor in
            operations.forEach { operation in
                operation.apply(editor: editor)
            }
        }
    }

    public func editSubscriptionLists(_ operations: Any) throws {
        let data = try JSONUtils.data(operations)
        let operations = try JSONDecoder().decode(
            [SubscriptionListOperation].self,
            from: data
        )

        try self.channel.editSubscriptionLists { editor in
            operations.forEach { operation in
                operation.apply(editor: editor)
            }
        }
    }
}

