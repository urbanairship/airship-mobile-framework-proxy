/* Copyright Urban Airship and Contributors */

import Foundation
import AirshipKit

@objc
public class AirshipChannelProxy: NSObject {
    private let channelProvider: () throws -> ChannelProtocol
    private var channel: ChannelProtocol {
        get throws { try channelProvider() }
    }

    init(channelProvider: @escaping () throws -> ChannelProtocol) {
        self.channelProvider = channelProvider
    }

    @objc
    public func enableChannelCreation() throws -> Void {
        try self.channel.enableChannelCreation()
    }

    @objc
    public func addTags(_ tags: [String]) throws {
        try self.channel.editTags { editor in
            editor.add(tags)
        }
    }

    @objc
    public func removeTags(_ tags: [String]) throws {
        try self.channel.editTags { editor in
            editor.remove(tags)
        }
    }

    @objc
    public func getTags() throws -> [String] {
        return try self.channel.tags
    }

    @objc
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

    @objc(getChannelIdOrEmptyWithError:)
    public func _getChannelId() throws -> String {
        return try getChannelId() ?? ""
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

    @objc
    public func editAttributes(json: Any) throws {
        let data = try JSONUtils.data(json)
        let operations = try JSONDecoder().decode(
            [AttributeOperation].self,
            from: data
        )
        try editAttributes(operations: operations)
    }


    public func editAttributes(operations: [AttributeOperation]) throws {
        try self.channel.editAttributes { editor in
            operations.forEach { operation in
                operation.apply(editor: editor)
            }
        }
    }

    @objc
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

