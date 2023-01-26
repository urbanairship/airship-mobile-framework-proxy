/* Copyright Urban Airship and Contributors */

import Foundation
import AirshipKit

public enum AirshipMessageCenterProxyError: Error {
    case messageNotFound
    case refreshFailed
}

@objc
public class AirshipMessageCenterProxy: NSObject {
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

    @objc
    public func display(messageID: String?) throws {
        if let messageID = messageID {
            try self.messageCenter.display(messageID: messageID)
        } else {
            try self.messageCenter.display()
        }
    }

    @objc
    public func dismiss() throws {
        try self.messageCenter.dismiss()
    }

    public func getMessages() throws -> [AirshipMessageCenterMessage] {
        return try self.messageCenter.messages
    }

    @objc
    public func getMessagesJSON() throws -> [Any] {
        let messages = try self.messageCenter.messages
        let data = try JSONEncoder().encode(messages)
        guard
            let result = try JSONSerialization.jsonObject(
                with: data,
                options: .fragmentsAllowed
            ) as? [Any]
        else {
            throw AirshipErrors.parseError("Invalid message center JSON")
        }

        return result
    }

    @objc
    public func getUnreadCount() async throws -> Int {
        return try self.messageCenter.unreadCount
    }

    @objc
    public func deleteMessage(
        messageID: String
    ) async throws {
        guard
            try await self.messageCenter.deleteMessage(
                messageID: messageID
            )
        else {
            throw AirshipMessageCenterProxyError.messageNotFound
        }
    }

    @objc
    public func markMessageRead(
        messageID:String
    ) async throws {
        guard
            try await self.messageCenter.markMessageRead(
                messageID: messageID
            )
        else {
            throw AirshipMessageCenterProxyError.messageNotFound
        }
    }

    @objc
    public func refresh() async throws {
        guard try await self.messageCenter.refresh() else {
            throw AirshipMessageCenterProxyError.refreshFailed
        }
    }

    @objc
    public func setAutoLaunchDefaultMessageCenter(_ enabled: Bool) {
        self.proxyStore.autoDisplayMessageCenter = enabled
    }
}

protocol MessageCenterProtocol: AnyObject {
    func display()
    func display(messageID: String)
    func dismiss()
    var messages: [AirshipMessageCenterMessage] { get throws }
    func deleteMessage(messageID: String) async throws -> Bool
    func markMessageRead(messageID: String) async throws -> Bool
    func refresh() async throws -> Bool
    var unreadCount: Int { get }
}

extension MessageCenter: MessageCenterProtocol {
    var unreadCount: Int {
        return self.messageList.unreadCount
    }

    func refresh() async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            self.messageList.retrieveMessageList {
                continuation.resume(returning: true)
            } withFailureBlock: {
                continuation.resume(returning: false)
            }
        }
    }

    func display(messageID: String) {
        self.displayMessage(forID: messageID)
    }

    var messages: [AirshipMessageCenterMessage] {
        get throws {
            return try self.messageList.messages.map { message in
                var listIconURL: String?
                if let icons = message.rawMessageObject["icons"] as? [String : Any] {
                    listIconURL = icons["listIcon"] as? String
                }

                var expiry: Int?
                if let expirationDate = message.messageExpiration {
                    expiry = Int(
                        expirationDate.timeIntervalSince1970 * 1000
                    )
                }

                return AirshipMessageCenterMessage(
                    title: message.title,
                    identifier: message.messageID,
                    sentDate: Int(
                        message.messageSent.timeIntervalSince1970 * 1000
                    ),
                    listIconURL: listIconURL,
                    isRead: !message.unread,
                    extras: try AirshipJSON.wrap(message.extra),
                    expirationDate: expiry
                )
            }
        }

    }

    func deleteMessage(messageID: String) async throws -> Bool {
        guard
            let message = self.messageList.message(
                forID: messageID
            )
        else {
            return false
        }

        return await withCheckedContinuation { continuation in
            self.messageList.markMessagesDeleted([message]) {
                continuation.resume(returning: true)
            }
        }
    }

    func markMessageRead(messageID: String) async throws -> Bool {
        guard
            let message = self.messageList.message(
                forID: messageID
            )
        else {
            return false
        }

        return await withCheckedContinuation { continuation in
            self.messageList.markMessagesRead([message]) {
                continuation.resume(returning: true)
            }
        }
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

    private enum CodingKeys: String, CodingKey {
        case title = "title"
        case identifier = "id"
        case sentDate = "sentDate"
        case listIconURL = "listIconURL"
        case isRead = "isRead"
        case extras = "extras"
        case expirationDate = "expirationDate"
    }
}

