import Foundation
import AirshipKit

public enum AirshipProxyEventType: CaseIterable {
    case deepLinkReceived
    case channelCreated
    case pushTokenReceived
    case messageCenterUpdated
    case displayMessageCenter
    case notificationResponseReceived
    case pushReceived
}

public protocol AirshipProxyEvent {
    var type: AirshipProxyEventType { get }
    var body: [String: Any] { get }
}

struct DeepLinkEvent: AirshipProxyEvent {
    let type: AirshipProxyEventType = AirshipProxyEventType.deepLinkReceived
    let body: [String: Any]

    init(_ deepLink: URL) {
        self.body = ["deepLink": deepLink.absoluteString]
    }
}

struct ChannelCreatedEvent: AirshipProxyEvent {
    let type: AirshipProxyEventType = .channelCreated
    let body: [String: Any]

    init(_ channelID: String) {
        self.body = ["channelId": channelID]
    }
}

struct MessageCenterUpdatedEvent: AirshipProxyEvent {
    let type: AirshipProxyEventType = .messageCenterUpdated
    let body: [String: Any]

    init(messageCount: UInt, unreadCount: Int) {
        self.body = [
            "messageCount": messageCount,
            "unreadCount": unreadCount
        ]
    }
}

struct DisplayMessageCenterEvent: AirshipProxyEvent {
    let type: AirshipProxyEventType = .displayMessageCenter
    let body: [String: Any]

    init(messageID: String? = nil) {
        if let messageID = messageID {
            self.body = [
                "messageID": messageID
            ]
        } else {
            self.body = [:]
        }

    }
}

struct NotificationResponseEvent: AirshipProxyEvent {
    let type: AirshipProxyEventType = .notificationResponseReceived
    var body: [String : Any]

    init(response: UNNotificationResponse) {
        self.body = PushUtils.responsePayload(response)
    }
}

struct PushReceivedEvent: AirshipProxyEvent {
    let type: AirshipProxyEventType = .pushReceived
    var body: [String : Any]

    init(userInfo: [AnyHashable : Any]) {
        self.body = PushUtils.contentPayload(userInfo)
    }
}

struct PushTokenReceived: AirshipProxyEvent {
    let type: AirshipProxyEventType = .pushTokenReceived
    var body: [String : Any]

    init(pushToken: String) {
        self.body = ["pushToken": pushToken]
    }
}

