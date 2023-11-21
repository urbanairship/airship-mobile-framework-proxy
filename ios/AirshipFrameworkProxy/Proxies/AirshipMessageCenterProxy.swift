/* Copyright Urban Airship and Contributors */

import Foundation
import AirshipKit

public enum AirshipMessageCenterProxyError: Error {
    case messageNotFound
    case refreshFailed
}

public class AirshipMessageCenterProxy {
    private let proxyStore: ProxyStore
    private let messageCenterProvider: () throws -> MessageCenterProtocol
    private var messageCenter: MessageCenterProtocol {
        get throws { try messageCenterProvider() }
    }

    init(
        proxyStore: ProxyStore,
        messageCenterProvider: @escaping () throws -> MessageCenterProtocol
    ) {
        self.proxyStore = proxyStore
        self.messageCenterProvider = messageCenterProvider
    }

    public func display(messageID: String?) throws {
        if let messageID = messageID {
            try self.messageCenter.display(messageID: messageID)
        } else {
            try self.messageCenter.display()
        }
    }

    public func dismiss() throws {
        try self.messageCenter.dismiss()
    }

    public func getMessages() async throws -> [AirshipMessageCenterMessage] {
        return try await self.messageCenter.messages
    }

    public func getMessage(messageID: String) async throws -> AirshipMessageCenterMessage {
        return try await self.messageCenter.message(forID: messageID)
    }

    public func getUnreadCount() async throws -> Int {
        return try await self.messageCenter.unreadCount
    }

    public func deleteMessage(
        messageID: String
    ) async throws {
        try await self.messageCenter.deleteMessage(
            messageID: messageID
        )
    }

    public func markMessageRead(
        messageID:String
    ) async throws {
        try await self.messageCenter.markMessageRead(
            messageID: messageID
        )
    }

    public func refresh() async throws {
        guard try await self.messageCenter.refresh() else {
            throw AirshipMessageCenterProxyError.refreshFailed
        }
    }

    public func setAutoLaunchDefaultMessageCenter(_ enabled: Bool) {
        self.proxyStore.autoDisplayMessageCenter = enabled
    }
}

protocol MessageCenterProtocol: AnyObject {
    func display()
    func display(messageID: String)
    func dismiss()
    func message(forID messageID: String) async throws -> AirshipMessageCenterMessage
    var messages: [AirshipMessageCenterMessage] { get async }
    func deleteMessage(messageID: String) async throws
    func markMessageRead(messageID: String) async throws
    func refresh() async throws -> Bool
    var unreadCount: Int { get async }
}

extension MessageCenter: MessageCenterProtocol {
    var unreadCount: Int {
        get async {
            return await self.inbox.unreadCount
        }
    }

    func refresh() async throws -> Bool {
        return await inbox.refreshMessages()
    }


    func message(forID messageID: String) async throws -> AirshipMessageCenterMessage {
        guard let message = await self.inbox.message(forID: messageID) else {
            throw AirshipMessageCenterProxyError.messageNotFound
        }

        return AirshipMessageCenterMessage(message: message)
    }

    var messages: [AirshipMessageCenterMessage] {
        get async {
            return await self.inbox.messages.map {
                AirshipMessageCenterMessage(message: $0)
            }
        }
    }

    func deleteMessage(messageID: String) async throws {
        guard await self.inbox.message(forID: messageID) != nil else {
            throw AirshipMessageCenterProxyError.messageNotFound
        }
        return await self.inbox.delete(messageIDs: [messageID])
    }

    func markMessageRead(messageID: String) async throws {
        guard await self.inbox.message(forID: messageID) != nil else {
            throw AirshipMessageCenterProxyError.messageNotFound
        }
        return await self.inbox.markRead(messageIDs: [messageID])
    }
}

public struct AirshipMessageCenterMessage: Codable {
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

