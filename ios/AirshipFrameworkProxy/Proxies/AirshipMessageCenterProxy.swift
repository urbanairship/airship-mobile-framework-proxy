/* Copyright Urban Airship and Contributors */

import Foundation

#if canImport(AirshipKit)
import AirshipKit
#elseif canImport(AirshipCore)
import AirshipCore
import AirshipMessageCenter
#endif

public enum AirshipMessageCenterProxyError: Error, Sendable {
    case messageNotFound
    case refreshFailed
}

public final class AirshipMessageCenterProxy: Sendable {
    private let proxyStore: ProxyStore
    private let messageCenterProvider: @Sendable () throws -> MessageCenter
    private var messageCenter: MessageCenter {
        get throws { try messageCenterProvider() }
    }

    init(
        proxyStore: ProxyStore,
        messageCenterProvider: @Sendable @escaping () throws -> MessageCenter
    ) {
        self.proxyStore = proxyStore
        self.messageCenterProvider = messageCenterProvider
    }

    @MainActor
    public func display(messageID: String?) throws {
        if let messageID = messageID {
            try self.messageCenter.display(messageID: messageID)
        } else {
            try self.messageCenter.display()
        }
    }

    @MainActor
    public func showMessageCenter(messageID: String?) throws {
        DefaultMessageCenterUI.shared.display(messageID: messageID)
    }

    @MainActor
    public func showMessageView(messageID: String) throws {
        DefaultMessageCenterUI.shared.displayMessageView(messageID: messageID)
    }

    @MainActor
    public func dismiss() throws {
        try self.messageCenter.dismiss()
    }

    public var messages: [AirshipMessageCenterMessage] {
        get async throws {
            return try await self.messageCenter.inbox.messages.map {
                AirshipMessageCenterMessage(message: $0)
            }
        }
    }

    public func getMessage(messageID: String) async throws -> AirshipMessageCenterMessage {
        guard let message = try await self.messageCenter.inbox.message(forID: messageID) else {
            throw AirshipMessageCenterProxyError.messageNotFound
        }

        return AirshipMessageCenterMessage(message: message)
    }

    public var unreadCount: Int {
        get async throws {
            return try await self.messageCenter.inbox.unreadCount
        }
    }

    public func deleteMessage(
        messageID: String
    ) async throws {
        guard try await self.messageCenter.inbox.message(forID: messageID) != nil else {
            throw AirshipMessageCenterProxyError.messageNotFound
        }
        return try await self.messageCenter.inbox.delete(messageIDs: [messageID])
    }

    public func markMessageRead(
        messageID:String
    ) async throws {
        guard try await self.messageCenter.inbox.message(forID: messageID) != nil else {
            throw AirshipMessageCenterProxyError.messageNotFound
        }
        return try await self.messageCenter.inbox.markRead(messageIDs: [messageID])
    }

    public func refresh() async throws {
        guard try await self.messageCenter.inbox.refreshMessages() else {
            throw AirshipMessageCenterProxyError.refreshFailed
        }
    }

    @MainActor
    public func setAutoLaunchDefaultMessageCenter(_ enabled: Bool) {
        self.proxyStore.autoDisplayMessageCenter = enabled
    }
}


public struct AirshipMessageCenterMessage: Codable, Sendable {
    let title: String
    let identifier: String
    let sentDate: Int
    let listIconURL: String?
    let isRead: Bool
    let extras: AirshipJSON
    let expirationDate: Int?


    init(message: MessageCenterMessage) {
        var expiry: Int?
        if let expirationDate = message.expirationDate {
            expiry = Int(
                expirationDate.timeIntervalSince1970 * 1000
            )
        }

        self.title = message.title
        self.identifier = message.id
        self.sentDate = Int(
                message.sentDate.timeIntervalSince1970 * 1000
            )
        self.listIconURL = message.listIcon
        self.isRead = !message.unread
        self.extras = try! AirshipJSON.wrap(message.extra)
        self.expirationDate = expiry
    }

    private enum CodingKeys: String, CodingKey {
        case title = "title"
        case identifier = "id"
        case sentDate = "sentDate"
        case listIconURL = "listIconUrl"
        case isRead = "isRead"
        case extras = "extras"
        case expirationDate = "expirationDate"
    }
}

