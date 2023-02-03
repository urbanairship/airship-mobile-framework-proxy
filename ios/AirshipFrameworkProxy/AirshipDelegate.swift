/* Copyright Airship and Contributors */

import Foundation
import AirshipKit

class AirshipDelegate: NSObject,
                       PushNotificationDelegate,
                       MessageCenterDisplayDelegate,
                       PreferenceCenterOpenDelegate,
                       RegistrationDelegate,
                       DeepLinkDelegate
{

    let proxyStore: ProxyStore
    let eventEmitter: AirshipProxyEventEmitter

    init(
        proxyStore: ProxyStore = ProxyStore.shared,
        eventEmitter: AirshipProxyEventEmitter = AirshipProxyEventEmitter.shared
    ) {
        self.proxyStore = proxyStore
        self.eventEmitter = eventEmitter
    }
    
    func displayMessageCenter(
        forMessageID messageID: String,
        animated: Bool
    ) {
        guard !self.proxyStore.autoDisplayMessageCenter else {
            MessageCenter.shared.defaultUI.displayMessageCenter(
                forMessageID: messageID,
                animated: animated
            )
            return
        }

        Task {
            await self.eventEmitter.addEvent(
                DisplayMessageCenterEvent(
                    messageID: messageID
                )
            )
        }
    }

    func displayMessageCenter(animated: Bool) {
        guard !self.proxyStore.autoDisplayMessageCenter else {
            MessageCenter.shared.defaultUI.displayMessageCenter(
                animated: animated
            )
            return
        }

        Task {
            await self.eventEmitter.addEvent(
                DisplayMessageCenterEvent()
            )
        }
    }

    func dismissMessageCenter(animated: Bool) {
        MessageCenter.shared.defaultUI.dismissMessageCenter(
            animated: animated
        )
    }

    func openPreferenceCenter(
        _ preferenceCenterID: String
    ) -> Bool {
        let autoLaunch = self.proxyStore.shouldAutoLaunchPreferenceCenter(
            preferenceCenterID
        )

        guard !autoLaunch else {
            return false
        }

        Task {
            await self.eventEmitter.addEvent(
                DisplayPreferenceCenterEvent(
                    preferenceCenterID: preferenceCenterID
                )
            )
        }

        return true
    }

    func receivedDeepLink(
        _ deepLink: URL,
        completionHandler: @escaping () -> Void
    ) {
        Task {
            await self.eventEmitter.addEvent(
                DeepLinkEvent(deepLink)
            )
        }
    }

    func messageCenterInboxUpdated() {
        Task {
            let messageList = MessageCenter.shared.messageList
            await self.eventEmitter.addEvent(
                MessageCenterUpdatedEvent(
                    messageCount: messageList.messageCount(),
                    unreadCount: messageList.unreadCount
                )
            )
        }

    }

    func channelCreated() {
        guard let channelID = Airship.channel.identifier else {
            return
        }

        Task {
            await self.eventEmitter.addEvent(
                ChannelCreatedEvent(channelID)
            )
        }
    }

    func receivedNotificationResponse(
        _ notificationResponse: UNNotificationResponse,
        completionHandler: @escaping () -> Void
    ) {
        guard
            notificationResponse.actionIdentifier != UNNotificationDismissActionIdentifier
        else {
            completionHandler()
            return
        }

        Task {
            await self.eventEmitter.addEvent(
                NotificationResponseEvent(
                    response: notificationResponse
                )
            )
            completionHandler()
        }
    }

    func receivedBackgroundNotification(
        _ userInfo: [AnyHashable : Any],
        completionHandler: @escaping (UIBackgroundFetchResult
    ) -> Void) {
        Task {
            await self.eventEmitter.addEvent(
                PushReceivedEvent(
                    userInfo: userInfo
                )
            )
            completionHandler(.noData)
        }
    }

    func receivedForegroundNotification(
        _ userInfo: [AnyHashable : Any],
        completionHandler: @escaping () -> Void
    ) {
        Task {
            await self.eventEmitter.addEvent(
                PushReceivedEvent(
                    userInfo: userInfo
                )
            )
            completionHandler()
        }
    }

    func apnsRegistrationSucceeded(withDeviceToken deviceToken: Data) {
        let token = Utils.deviceTokenStringFromDeviceToken(deviceToken)
        Task {
            await self.eventEmitter.addEvent(
                PushTokenReceivedEvent(
                    pushToken: token
                )
            )
        }
    }

    func notificationAuthorizedSettingsDidChange(_ authorizedSettings: UAAuthorizedNotificationSettings
    ) {
        Task {
            await self.eventEmitter.addEvent(
                NotificationOptInStatusChangedEvent(
                    authorizedSettings: authorizedSettings
                )
            )
        }
    }
}
