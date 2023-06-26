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
    
    func displayMessageCenter(messageID: String) {
        Task { @MainActor in
            guard !self.proxyStore.autoDisplayMessageCenter else {
                DefaultMessageCenter.shared.display(messageID: messageID)
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
                DefaultMessageCenter.shared.display()
                return
            }

            await self.eventEmitter.addEvent(
                DisplayMessageCenterEvent()
            )
        }
    }

    func dismissMessageCenter() {
        Task { @MainActor in
            DefaultMessageCenter.shared.dismiss()
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
                NotificationOptInStatusChangedEvent(
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

public class DefaultMessageCenter {
    static let shared: DefaultMessageCenter = DefaultMessageCenter()
    private var currentDisplay: Disposable?
    private var controller: MessageCenterController = MessageCenterController()

    @MainActor
    func dismiss() {
        self.currentDisplay?.dispose()
    }

    @MainActor
    func display(messageID: String? = nil) {
        guard let scene = try? AirshipUtils.findWindowScene() else {
            AirshipLogger.error(
                "Unable to display message center, missing scene."
            )
            return
        }

        controller.navigate(messageID: messageID)

        currentDisplay?.dispose()

        AirshipLogger.debug("Opening default message center UI")

        self.currentDisplay = open(
            scene: scene,
            theme: MessageCenter.shared.theme
        )
    }

    @MainActor
    private func open(
        scene: UIWindowScene,
        theme: MessageCenterTheme?
    ) -> Disposable {
        var window: UIWindow? = UIWindow(windowScene: scene)

        let disposable = Disposable {
            window?.windowLevel = .normal
            window?.isHidden = true
            window = nil
        }

        let viewController = MessageCenterViewControllerFactory.make(
            theme: theme,
            controller: self.controller
        ) {
            disposable.dispose()
        }

        window?.isHidden = false
        window?.windowLevel = .alert
        window?.makeKeyAndVisible()
        window?.rootViewController = viewController

        return disposable
    }
}
