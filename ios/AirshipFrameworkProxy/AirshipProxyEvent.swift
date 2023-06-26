import Foundation
import AirshipKit

public enum AirshipProxyEventType: CaseIterable {
    case deepLinkReceived
    case channelCreated
    case pushTokenReceived
    case messageCenterUpdated
    case displayMessageCenter
    case displayPreferenceCenter

    case notificationResponseReceived
    case pushReceived
    case notificationStatusChanged
    case authorizedNotificationOptionsChanged
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

    init(messageCount: Int, unreadCount: Int) {
        self.body = [
            "messageCount": messageCount,
            "messageUnreadCount": unreadCount
        ]
    }
}

struct DisplayMessageCenterEvent: AirshipProxyEvent {
    let type: AirshipProxyEventType = .displayMessageCenter
    let body: [String: Any]

    init(messageID: String? = nil) {
        if let messageID = messageID {
            self.body = [
                "messageId": messageID
            ]
        } else {
            self.body = [:]
        }

    }
}

struct DisplayPreferenceCenterEvent: AirshipProxyEvent {
    let type: AirshipProxyEventType = .displayPreferenceCenter
    let body: [String: Any]

    init(preferenceCenterID: String) {
        self.body = [
            "preferenceCenterId": preferenceCenterID
        ]
    }
}

struct NotificationResponseEvent: AirshipProxyEvent {
    let type: AirshipProxyEventType = .notificationResponseReceived
    let body: [String : Any]

    @MainActor
    init(response: UNNotificationResponse) {
        var body: [String: Any] = [:]
        body["pushPayload"] = PushUtils.contentPayload(
            response.notification.request.content.userInfo,
            notificationID: response.notification.request.identifier
        )

        if (response.actionIdentifier == UNNotificationDefaultActionIdentifier) {
            body["isForeground"] = true
        } else {
            if let action = PushUtils.findAction(response) {
                body["isForeground"] = action.options.contains(.foreground)
            } else {
                body["isForeground"] = true
            }
            body["actionId"] = response.actionIdentifier
        }

        self.body = body
    }
}

struct PushReceivedEvent: AirshipProxyEvent {
    let type: AirshipProxyEventType = .pushReceived
    let body: [String : Any]

    init(userInfo: [AnyHashable : Any]) {
        self.body = [
            "pushPayload": PushUtils.contentPayload(userInfo)
        ]
    }
}

struct PushTokenReceivedEvent: AirshipProxyEvent {
    let type: AirshipProxyEventType = .pushTokenReceived
    let body: [String : Any]

    init(pushToken: String) {
        self.body = ["pushToken": pushToken]
    }
}


struct NotificationStatusChangedEvent: AirshipProxyEvent {
    let type: AirshipProxyEventType = .notificationStatusChanged

    let body: [String: Any]

    init(
        status: NotificationStatus
    ) {
        self.body = status.toMap
    }
}


struct AuthorizedNotificationOptionsChangedEvent: AirshipProxyEvent {
    let type: AirshipProxyEventType = .authorizedNotificationOptionsChanged

    let body: [String: Any]

    init(
        authorizedSettings: UAAuthorizedNotificationSettings
    ) {
        self.body = [
            "authorizedOptions": authorizedSettings.names
        ]
    }

}


