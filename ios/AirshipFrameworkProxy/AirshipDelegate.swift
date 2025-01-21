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

@MainActor
final class AirshipDelegate {

    let proxyStore: ProxyStore
    let eventEmitter: AirshipProxyEventEmitter

    init(
        proxyStore: ProxyStore = ProxyStore.shared,
        eventEmitter: AirshipProxyEventEmitter = AirshipProxyEventEmitter.shared
    ) {
        self.proxyStore = proxyStore
        self.eventEmitter = eventEmitter
    }

    func messageCenterInboxUpdated() {
        Task {
            await self.eventEmitter.addEvent(
                MessageCenterUpdatedEvent(
                    messageCount: await Airship.messageCenter.inbox.messages.count,
                    unreadCount: await Airship.messageCenter.inbox.unreadCount
                ),
                replacePending: true
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

}

extension AirshipDelegate: PushNotificationDelegate {

    @MainActor
    private var forwardPushDelegate: (any PushNotificationDelegate)? {
        AirshipPluginForwardDelegates.shared.pushNotificationDelegate
    }

    @MainActor
    func receivedForegroundNotification(_ userInfo: [AnyHashable : Any]) async {
        do {
            await self.eventEmitter.addEvent(
                try PushReceivedEvent(
                    userInfo: userInfo,
                    isForeground: true
                )
            )
        } catch {
            AirshipLogger.error("Failed to generate PushReceivedEvent \(error)")
        }

        await forwardPushDelegate?.receivedForegroundNotification(userInfo)
    }

    @MainActor
    func receivedBackgroundNotification(_ userInfo: [AnyHashable : Any]) async -> UIBackgroundFetchResult {
        do {
            await self.eventEmitter.addEvent(
                try PushReceivedEvent(
                    userInfo: userInfo,
                    isForeground: false
                )
            )
        } catch {
            AirshipLogger.error("Failed to generate PushReceivedEvent \(error)")
        }

        return await forwardPushDelegate?.receivedBackgroundNotification(userInfo) ?? .noData
    }

    @MainActor
    func receivedNotificationResponse(_ notificationResponse: UNNotificationResponse) async {

        do {
            if (notificationResponse.actionIdentifier != UNNotificationDismissActionIdentifier) {
                await self.eventEmitter.addEvent(
                    try NotificationResponseEvent(
                        response: notificationResponse
                    )
                )
            }
        } catch {
            AirshipLogger.error("Failed to generate NotificationResponseEvent \(error)")
        }

        await forwardPushDelegate?.receivedNotificationResponse(notificationResponse)
    }

    @MainActor
    func extendPresentationOptions(_ options: UNNotificationPresentationOptions, notification: UNNotification) async -> UNNotificationPresentationOptions {
        guard
            let forward = forwardPushDelegate?.extendPresentationOptions
        else {
            do {
                let overrides = try  await AirshipProxy.shared.push.presentationOptions(
                    notification: notification
                )
                return overrides ?? options
            } catch {
                AirshipLogger.error("Failed to extendPresentationOptions \(error)")
                return options
            }
        }

        return await forward(options, notification)
    }
}


extension AirshipDelegate: RegistrationDelegate {
    @MainActor
    private var forwardRegistrationDelegate: (any RegistrationDelegate)? {
        AirshipPluginForwardDelegates.shared.registrationDelegate
    }

    nonisolated func apnsRegistrationSucceeded(withDeviceToken deviceToken: Data) {
        let token = AirshipUtils.deviceTokenStringFromDeviceToken(deviceToken)
        Task { @MainActor in
            await self.eventEmitter.addEvent(
                PushTokenReceivedEvent(
                    pushToken: token
                ),
                replacePending: true
            )

            forwardRegistrationDelegate?.apnsRegistrationSucceeded(withDeviceToken: deviceToken)
        }
    }

    nonisolated func apnsRegistrationFailedWithError(_ error: any Error) {
        Task { @MainActor in
            forwardRegistrationDelegate?.apnsRegistrationFailedWithError(error)
        }
    }

    nonisolated func notificationAuthorizedSettingsDidChange(
        _ authorizedSettings: AirshipAuthorizedNotificationSettings
    ) {
        Task { @MainActor in
            await self.eventEmitter.addEvent(
                AuthorizedNotificationSettingsChangedEvent(
                    authorizedSettings: authorizedSettings
                ),
                replacePending: true
            )

            forwardRegistrationDelegate?.notificationAuthorizedSettingsDidChange(authorizedSettings)
        }
    }
}

extension AirshipDelegate: MessageCenterDisplayDelegate {
    @MainActor
    func displayMessageCenter(messageID: String) {
        guard !self.proxyStore.autoDisplayMessageCenter else {
            DefaultMessageCenterUI.shared.display(messageID: messageID)
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

    func displayMessageCenter() {
        guard !self.proxyStore.autoDisplayMessageCenter else {
            DefaultMessageCenterUI.shared.display()
            return
        }

        Task {
            await self.eventEmitter.addEvent(
                DisplayMessageCenterEvent()
            )
        }
    }

    func dismissMessageCenter() {
        DefaultMessageCenterUI.shared.dismiss()
    }
}

extension AirshipDelegate: PreferenceCenterOpenDelegate {
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
}

extension AirshipDelegate: DeepLinkDelegate {
    func receivedDeepLink(
        _ deepLink: URL
    ) async {
        let delegate = AirshipPluginForwardDelegates.shared.deepLinkDelegate
        guard await delegate?.receivedDeepLink(deepLink) == true else {
            await self.eventEmitter.addEvent(
                DeepLinkEvent(deepLink)
            )
            return
        }
    }
}

