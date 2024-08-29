/* Copyright Airship and Contributors */

import Foundation
#if canImport(AirshipKit)
import AirshipKit
import Combine
#elseif canImport(AirshipCore)
import AirshipCore
import AirshipMessageCenter
import AirshipPreferenceCenter
import AirshipAutomation
#endif

class AirshipDelegate: NSObject,
                       PushNotificationDelegate,
                       MessageCenterDisplayDelegate,
                       PreferenceCenterOpenDelegate,
                       RegistrationDelegate,
                       DeepLinkDelegate
{

    let proxyStore: ProxyStore
    let eventEmitter: AirshipProxyEventEmitter

    var embeddedInfoSubscriptionTask: (Task<Void, Never>)?
    var subscriptions: Set<AnyCancellable> = Set()

    init(
        proxyStore: ProxyStore = ProxyStore.shared,
        eventEmitter: AirshipProxyEventEmitter = AirshipProxyEventEmitter.shared
    ) {
        self.proxyStore = proxyStore
        self.eventEmitter = eventEmitter


        super.init()

        /// Keep reference to the subscription task that needs to run on main actor
        let embeddedInfoSubscriptionTask = Task { @MainActor in
            AirshipEmbeddedObserver().$embeddedInfos.sink { embeddedInfo in
                self.embeddedInfoUpdated(embeddedInfo: embeddedInfo)
            }.store(in: &self.subscriptions)
        }
    }

    deinit {
        embeddedInfoSubscriptionTask?.cancel()
    }
    
    func displayMessageCenter(messageID: String) {
        Task { @MainActor in
            guard !self.proxyStore.autoDisplayMessageCenter else {
                DefaultMessageCenterUI.shared.display(messageID: messageID)
                return
            }

            await self.eventEmitter.addEvent(
                DisplayMessageCenterEvent(
                    messageID: messageID
                )
            )
        }
    }

    func displayMessageCenter() {


        Task { @MainActor in
            guard !self.proxyStore.autoDisplayMessageCenter else {
                DefaultMessageCenterUI.shared.display()
                return
            }

            await self.eventEmitter.addEvent(
                DisplayMessageCenterEvent()
            )
        }
    }

    func dismissMessageCenter() {
        Task { @MainActor in
            DefaultMessageCenterUI.shared.dismiss()
        }
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
        _ deepLink: URL
    ) async {
        await self.eventEmitter.addEvent(
            DeepLinkEvent(deepLink)
        )
    }

    func messageCenterInboxUpdated() {
        Task {
            await self.eventEmitter.addEvent(
                MessageCenterUpdatedEvent(
                    messageCount: await MessageCenter.shared.inbox.messages.count,
                    unreadCount: await MessageCenter.shared.inbox.unreadCount
                )
            )
        }

    }

    func embeddedInfoUpdated(embeddedInfo: [AirshipEmbeddedInfo]) {
        Task {
            await self.eventEmitter.addEvent(
                EmbeddedInfoUpdatedEvent(
                    embeddedInfo: embeddedInfo
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
                    userInfo: userInfo,
                    isForeground: false
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
                    userInfo: userInfo,
                    isForeground: true
                )
            )
            completionHandler()
        }
    }

    func apnsRegistrationSucceeded(withDeviceToken deviceToken: Data) {
        let token = AirshipUtils.deviceTokenStringFromDeviceToken(deviceToken)
        Task {
            await self.eventEmitter.addEvent(
                PushTokenReceivedEvent(
                    pushToken: token
                )
            )
        }
    }

    func notificationAuthorizedSettingsDidChange(
        _ authorizedSettings: UAAuthorizedNotificationSettings
    ) {
        Task {
            await self.eventEmitter.addEvent(
                AuthorizedNotificationSettingsChangedEvent(
                    authorizedSettings: authorizedSettings
                )
            )
        }
    }

    @MainActor
    func extendPresentationOptions(
        _ options: UNNotificationPresentationOptions,
        notification: UNNotification,
        completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        Task {
            let overrides = await AirshipProxy.shared.push.presentationOptions(
                notification: notification
            )
            completionHandler(overrides ?? options)
        }
    }
}

