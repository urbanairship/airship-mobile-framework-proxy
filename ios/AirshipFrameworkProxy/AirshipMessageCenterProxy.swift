/* Copyright Urban Airship and Contributors */

import Foundation
import AirshipKit

public enum AirshipMessageCenterProxyError: Error {
    case messageNotFound
    case failedToRefresh
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

    public func displayMessageCenter() throws {
        try self.messageCenter.display()
    }

    public func dismissMessageCenter() throws {
        try self.messageCenter.dismiss()
    }

    public func displayMessage(
        _ messageID: String
    ) throws {
        try self.messageCenter.display(messageID: messageID)
    }

    public var messages: [[String: Any]] {
        get throws {
            return try self.messageCenter.messages.map { message in
                var messageInfo : [String : Any] = [:]
                messageInfo["title"] = message.title
                messageInfo["id"] = message.messageID
                messageInfo["sentDate"] = message.messageSent.timeIntervalSince1970 * 1000
                messageInfo["isRead"] = message.unread ? false : true
                messageInfo["extras"] = message.extra

                if let icons = message.rawMessageObject["icons"] as? [String : Any] {
                    messageInfo["listIconUrl"] = icons["listIcon"]
                }
                return messageInfo
            }
        }
    }

    public var  unreadCount: Int {
        get throws {
            return try self.messageCenter.unreadCount
        }
    }

    public func deleteMessage(
        messageID: String
    ) async throws {
        try await self.messageCenter.deleteMessage(messageID: messageID)
    }

    public func markMessageRead(
        messageID:String
    ) async throws {
        try await self.messageCenter.markMessageRead(messageID: messageID)
    }

    public func refresh() async throws {
        try await self.messageCenter.refresh()
    }

    public func setAutoLaunchDefaultMessageCenter(_ enabled: Bool) {
        self.proxyStore.autoDisplayMessageCenter = enabled
    }
}

protocol MessageCenterProtocol: AnyObject {
    func display()
    func display(messageID: String)
    func dismiss()
    var messages: [AirshipMessageCenterMessage] { get }
    func deleteMessage(messageID: String) async throws
    func markMessageRead(messageID: String) async throws
    func refresh() async throws
    var unreadCount: Int { get }
}

extension MessageCenter: MessageCenterProtocol {
    var unreadCount: Int {
        return self.messageList.unreadCount
    }

    func refresh() async throws {
        try await withCheckedThrowingContinuation { continuation in
            self.messageList.retrieveMessageList {
                continuation.resume()
            } withFailureBlock: {
                continuation.resume(
                    throwing: AirshipMessageCenterProxyError.failedToRefresh
                )
            }
        }
    }

    func display(messageID: String) {
        self.displayMessage(forID: messageID)
    }

    var messages: [AirshipMessageCenterMessage] {
        return self.messageList.messages
    }

    func deleteMessage(messageID: String) async throws {
        guard
            let message = self.messageList.message(
                forID: messageID
            )
        else {
            throw AirshipMessageCenterProxyError.messageNotFound
        }

        await withCheckedContinuation { continuation in
            self.messageList.markMessagesDeleted([message]) {
                continuation.resume()
            }
        }
    }

    func markMessageRead(messageID: String) async throws {
        guard
            let message = self.messageList.message(
                forID: messageID
            )
        else {
            throw AirshipMessageCenterProxyError.messageNotFound
        }

        await withCheckedContinuation { continuation in
            self.messageList.markMessagesRead([message]) {
                continuation.resume()
            }
        }
    }
}

protocol AirshipMessageCenterMessage {
    var title: String { get }
    var messageID: String { get }
    var unread: Bool { get }
    var messageSent: Date { get }
    var messageExpiration: Date? { get }
    var rawMessageObject: [AnyHashable: Any] { get }
    var extra: [AnyHashable: Any] { get }
}

extension InboxMessage: AirshipMessageCenterMessage {
}
