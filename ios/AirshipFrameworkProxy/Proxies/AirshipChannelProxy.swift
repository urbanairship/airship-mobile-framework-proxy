/* Copyright Urban Airship and Contributors */

import Foundation
import AirshipKit

public class AirshipChannelProxy {
    private let channelProvider: () throws -> AirshipChannelProtocol
    private var channel: AirshipChannelProtocol {
        get throws { try channelProvider() }
    }

    init(channelProvider: @escaping () throws -> AirshipChannelProtocol) {
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
    
    @objc
    public func editTags(json: Any) throws {
        let data = try JSONUtils.data(json)
        let operations = try JSONDecoder().decode(
            [TagOperation].self,
            from: data
        )
        try self.editTags(operations: operations)
    }

    public func editTags(operations: [TagOperation]) throws {
        try self.channel.editTags { editor in
            operations.forEach { operation in
                operation.apply(editor: editor)
            }
        }
    }

    public func getTags() throws -> [String] {
        return try self.channel.tags
    }

    public func getSubscriptionLists() async throws -> [String] {
        return try await self.channel.fetchSubscriptionLists()
    }

    public func getChannelId() throws -> String? {
        return try self.channel.identifier
    }

    @objc
    public func editTagGroups(json: Any) throws {
        let data = try JSONUtils.data(json)
        let operations = try JSONDecoder().decode(
            [TagGroupOperation].self,
            from: data
        )
        try self.editTagGroups(operations: operations)
    }

    public func editTagGroups(operations: [TagGroupOperation]) throws {
        try self.channel.editTagGroups { editor in
            operations.forEach { operation in
                operation.apply(editor: editor)
            }
        }
    }

    public func editAttributes(json: Any) throws {
        let data = try JSONUtils.data(json)
        let operations = try JSONDecoder().decode(
            [AttributeOperation].self,
            from: data
        )
        try editAttributes(operations: operations)
    }


    public func editAttributes(operations: [AttributeOperation]) throws {
        let editor = try self.channel.editAttributes()
        try operations.forEach { operation in
            try operation.apply(editor: editor)
        }
        editor.apply()
    }

    public func editSubscriptionLists(json: Any) throws {
        let data = try JSONUtils.data(json)
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

