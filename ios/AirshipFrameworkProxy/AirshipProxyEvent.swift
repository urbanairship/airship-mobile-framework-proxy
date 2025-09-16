import Foundation
import UserNotifications

#if canImport(AirshipKit)
import AirshipKit
#elseif canImport(AirshipCore)
import AirshipCore
#endif

public enum AirshipProxyEventType: CaseIterable, Equatable, Sendable {
    case deepLinkReceived
    case channelCreated
    case pushTokenReceived
    case messageCenterUpdated
    case displayMessageCenter
    case displayPreferenceCenter

    case notificationResponseReceived
    case pushReceived
    case notificationStatusChanged
    case authorizedNotificationSettingsChanged
    case overridePresentationOptions

    case pendingEmbeddedUpdated
    case liveActivitiesUpdated
}

public protocol AirshipProxyEvent: Sendable {
    associatedtype T: Codable

    var type: AirshipProxyEventType { get }
    var body: T { get }
}

struct DeepLinkEvent: AirshipProxyEvent {
    let type: AirshipProxyEventType = AirshipProxyEventType.deepLinkReceived
    let body: Body

    init(_ deepLink: URL) {
        self.body = Body(deepLink: deepLink.absoluteString)
    }

    struct Body: Codable, Sendable {
        let deepLink: String
    }
}

struct LiveActivitiesUpdatedEvent: AirshipProxyEvent {
    let type: AirshipProxyEventType = AirshipProxyEventType.liveActivitiesUpdated
    let body: Body

    init(_ liveActivities: [LiveActivityInfo]) {
        self.body = Body(activities: liveActivities)
    }

    struct Body: Codable, Sendable {
        let activities: [LiveActivityInfo]
    }
}

struct ChannelCreatedEvent: AirshipProxyEvent {
    let type: AirshipProxyEventType = .channelCreated
    let body: Body

    init(_ channelID: String) {
        self.body = Body(channelId: channelID)
    }

    struct Body: Codable, Sendable {
        let channelId: String
    }
}

struct MessageCenterUpdatedEvent: AirshipProxyEvent {
    let type: AirshipProxyEventType = .messageCenterUpdated
    let body: Body

    init(messageCount: Int, unreadCount: Int) {
        self.body = Body(messageCount: messageCount, messageUnreadCount: unreadCount)
    }

    struct Body: Codable, Sendable {
        let messageCount: Int
        let messageUnreadCount: Int
    }
}

struct DisplayMessageCenterEvent: AirshipProxyEvent {
    let type: AirshipProxyEventType = .displayMessageCenter
    let body: Body

    init(messageID: String? = nil) {
        self.body = Body(messageId: messageID)
    }

    struct Body: Codable, Sendable {
        let messageId: String?
    }
}

struct DisplayPreferenceCenterEvent: AirshipProxyEvent {
    let type: AirshipProxyEventType = .displayPreferenceCenter
    let body: Body

    init(preferenceCenterID: String) {
        self.body = Body(preferenceCenterId: preferenceCenterID)
    }

    struct Body: Codable, Sendable {
        let preferenceCenterId: String
    }
}

struct NotificationResponseEvent: AirshipProxyEvent {
    let type: AirshipProxyEventType = .notificationResponseReceived
    let body: Body

    @MainActor
    init(response: UNNotificationResponse) throws {
        let isForegorund: Bool = if (response.actionIdentifier == UNNotificationDefaultActionIdentifier) {
            true
        } else {
            if let action = PushUtils.findAction(response) {
                action.options.contains(.foreground)
            } else {
                true
            }
        }

        let actionId: String? = if response.actionIdentifier == UNNotificationDefaultActionIdentifier {
            nil
        } else {
            response.actionIdentifier
        }

        self.body = Body(
            pushPayload: try ProxyPushPayload(
                notification: response.notification
            ),
            isForeground: isForegorund,
            actionId: actionId
        )
    }

    struct Body: Codable, Sendable {
        let pushPayload: ProxyPushPayload
        let isForeground: Bool
        let actionId: String?
    }
}

struct PushReceivedEvent: AirshipProxyEvent {
    let type: AirshipProxyEventType = .pushReceived
    let body: Body

    init(userInfo: [AnyHashable : Any], isForeground: Bool) throws {
        self.body = Body(
            pushPayload: try ProxyPushPayload(userInfo: userInfo),
            isForeground: isForeground
        )
    }

    struct Body: Codable, Sendable {
        let pushPayload: ProxyPushPayload
        let isForeground: Bool
    }
}

struct PushTokenReceivedEvent: AirshipProxyEvent {
    let type: AirshipProxyEventType = .pushTokenReceived
    let body: Body

    init(pushToken: String) {
        self.body = Body(pushToken: pushToken)
    }

    struct Body: Codable, Sendable {
        let pushToken: String
    }
}

struct NotificationStatusChangedEvent: AirshipProxyEvent {
    let type: AirshipProxyEventType = .notificationStatusChanged
    let body: Body

    init(
        status: NotificationStatus
    ) {
        self.body = Body(status: status)
    }

    struct Body: Codable, Sendable {
        let status: NotificationStatus
    }
}


struct AuthorizedNotificationSettingsChangedEvent: AirshipProxyEvent {
    let type: AirshipProxyEventType = .authorizedNotificationSettingsChanged
    let body: Body

    init(
        authorizedSettings: AirshipAuthorizedNotificationSettings
    ) {
        self.body = Body(authorizedSettings: authorizedSettings.names)
    }

    struct Body: Codable, Sendable {
        let authorizedSettings: [String]
    }
}

struct EmbeddedInfoUpdatedEvent: AirshipProxyEvent {
    let type: AirshipProxyEventType = .pendingEmbeddedUpdated
    let body: Body

    init(pending: [AirshipEmbeddedInfo]) {
        self.body = Body(pending: pending.map { Embedded(embeddedId: $0.embeddedID) })
    }

    struct Body: Codable, Sendable {
        let pending: [Embedded]
    }

    struct Embedded: Codable, Sendable {
        let embeddedId: String
    }
}

