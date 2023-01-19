/* Copyright Urban Airship and Contributors */

import Foundation
import AirshipKit


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
    public func displayMessageCenter() throws {
        try self.messageCenter.display()
    }

    @objc
    public func dismissMessageCenter() throws {
        try self.messageCenter.dismiss()
    }

    @objc
    public func displayMessage(
        _ messageID: String
    ) throws {
        try self.messageCenter.display(messageID: messageID)
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
    public func _getUnreadCount() throws -> NSNumber {
        return try NSNumber(value: self.unreadCount)
    }

    public var unreadCount: Int {
        get throws {
            return try self.messageCenter.unreadCount
        }
    }

    @objc(deleteMessage:withError:)
    public func _deleteMessage(
        messageID: String
    ) async throws -> NSNumber {
        return try await NSNumber(value: self.deleteMessage(messageID: messageID))
    }

    public func deleteMessage(
        messageID: String
    ) async throws -> Bool {
        return try await self.messageCenter.deleteMessage(messageID: messageID)
    }

    @objc(markMessageRead:withError:)
    public func _markMessageRead(
        messageID: String
    ) async throws -> NSNumber {
        return try await NSNumber(
            value: self.markMessageRead(messageID: messageID)
        )
    }

    public func markMessageRead(
        messageID:String
    ) async throws -> Bool {
        return try await self.messageCenter.markMessageRead(messageID: messageID)
    }

    @objc(refreshWithError:)
    public func _refresh() async throws -> NSNumber {
        return try await NSNumber(value: self.refresh())
    }

    public func refresh() async throws -> Bool {
        return try await self.messageCenter.refresh()
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

