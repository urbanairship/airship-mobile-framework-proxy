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

class AirshipDelegate: NSObject {

    let proxyStore: ProxyStore
    let eventEmitter: AirshipProxyEventEmitter

    init(
        proxyStore: ProxyStore = ProxyStore.shared,
        eventEmitter: AirshipProxyEventEmitter = AirshipProxyEventEmitter.shared
    ) {
        self.proxyStore = proxyStore
        self.eventEmitter = eventEmitter
        super.init()
    }

    func messageCenterInboxUpdated() {
        Task {
            await self.eventEmitter.addEvent(
                MessageCenterUpdatedEvent(
                    messageCount: await MessageCenter.shared.inbox.messages.count,
                    unreadCount: await MessageCenter.shared.inbox.unreadCount
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
    private var forwardPushDelegate: PushNotificationDelegate? {
        AirshipPluginForwardDelegates.shared.pushNotificationDelegate
    }

    func receivedNotificationResponse(
        _ notificationResponse: UNNotificationResponse,
        completionHandler: @escaping () -> Void
    ) {
        Task { @MainActor in
            if (notificationResponse.actionIdentifier != UNNotificationDismissActionIdentifier) {
                await self.eventEmitter.addEvent(
                    NotificationResponseEvent(
                        response: notificationResponse
                    )
                )
            }

            guard
                let forward = forwardPushDelegate?.receivedNotificationResponse
            else {
                completionHandler()
                return
            }
            forward(notificationResponse, completionHandler)
        }
    }

    func receivedBackgroundNotification(
        _ userInfo: [AnyHashable : Any],
        completionHandler: @escaping (UIBackgroundFetchResult
    ) -> Void) {
        Task { @MainActor in
            await self.eventEmitter.addEvent(
                PushReceivedEvent(
                    userInfo: userInfo,
                    isForeground: false
                )
            )

            guard
                let forward = forwardPushDelegate?.receivedBackgroundNotification
            else {
                completionHandler(.noData)
                return
            }
            forward(userInfo, completionHandler)
        }
    }

    func receivedForegroundNotification(
        _ userInfo: [AnyHashable : Any],
        completionHandler: @escaping () -> Void
    ) {
        Task { @MainActor in
            await self.eventEmitter.addEvent(
                PushReceivedEvent(
                    userInfo: userInfo,
                    isForeground: true
                )
            )

            guard
                let forward = forwardPushDelegate?.receivedForegroundNotification
            else {
                completionHandler()
                return
            }
            forward(userInfo, completionHandler)
        }
    }

    func extendPresentationOptions(
        _ options: UNNotificationPresentationOptions,
        notification: UNNotification,
        completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        Task { @MainActor in
            guard
                let forward = forwardPushDelegate?.extendPresentationOptions
            else {
                let overrides = await AirshipProxy.shared.push.presentationOptions(
                    notification: notification
                )
                completionHandler(overrides ?? options)
                return
            }

            forward(options, notification, completionHandler)
        }
    }

    @preconcurrency @MainActor
    func extend(
        _ options: UNNotificationPresentationOptions,
        notification: UNNotification
    ) -> UNNotificationPresentationOptions {
        return forwardPushDelegate?.extend?(options, notification: notification) ?? options
    }
}


extension AirshipDelegate: RegistrationDelegate {
    @MainActor
    private var forwardRegistrationDelegate: RegistrationDelegate? {
        AirshipPluginForwardDelegates.shared.registrationDelegate
    }

    @preconcurrency @MainActor
    func apnsRegistrationSucceeded(withDeviceToken deviceToken: Data) {
        let token = AirshipUtils.deviceTokenStringFromDeviceToken(deviceToken)
        Task {
            await self.eventEmitter.addEvent(
                PushTokenReceivedEvent(
                    pushToken: token
                ),
                replacePending: true
            )
        }

        forwardRegistrationDelegate?.apnsRegistrationSucceeded?(withDeviceToken: deviceToken)
    }

    @preconcurrency @MainActor
    func apnsRegistrationFailedWithError(_ error: Error) {
        forwardRegistrationDelegate?.apnsRegistrationFailedWithError?(error)
    }

    @preconcurrency @MainActor
    func notificationAuthorizedSettingsDidChange(
        _ authorizedSettings: UAAuthorizedNotificationSettings
    ) {
        Task {
            await self.eventEmitter.addEvent(
                AuthorizedNotificationSettingsChangedEvent(
                    authorizedSettings: authorizedSettings
                ),
                replacePending: true
            )
        }

        forwardRegistrationDelegate?.notificationAuthorizedSettingsDidChange?(authorizedSettings)
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

