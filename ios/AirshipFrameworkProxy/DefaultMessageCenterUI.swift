import Foundation
import UIKit
import SwiftUI

#if canImport(AirshipKit)
import AirshipKit
#elseif canImport(AirshipCore)
import AirshipCore
import AirshipMessageCenter
#endif

@MainActor
public class DefaultMessageCenterUI {
    static let shared: DefaultMessageCenterUI = DefaultMessageCenterUI()
    private var currentDisplay: (any AirshipMainActorCancellable)?
    private var controller: MessageCenterController = MessageCenterController()

    func dismiss() {
        self.currentDisplay?.cancel()
    }

    func display(messageID: String? = nil) {
        guard let scene = try? AirshipSceneManager.shared.lastActiveScene else {
            AirshipLogger.error(
                "Unable to display message center, missing scene."
            )
            return
        }

        controller.navigate(messageID: messageID)

        currentDisplay?.cancel()

        AirshipLogger.debug("Opening default message center UI")

        self.currentDisplay = open(
            scene: scene,
            theme: Airship.messageCenter.theme
        )
    }

    func displayMessageView(messageID: String) {
        guard let scene = try? AirshipSceneManager.shared.lastActiveScene else {
            AirshipLogger.error(
                "Unable to display message center, missing scene."
            )
            return
        }

        currentDisplay?.cancel()

        self.currentDisplay = openMessageView(
            scene: scene,
            messageID: messageID,
            theme: Airship.messageCenter.theme
        )
    }

    private func open(
        scene: UIWindowScene,
        theme: MessageCenterTheme?
    ) -> any AirshipMainActorCancellable {
        var window: UIWindow? = AirshipWindowFactory.shared.makeWindow(windowScene: scene)

        let cancellable = AirshipMainActorCancellableBlock {
            window?.windowLevel = .normal
            window?.isHidden = true
            window = nil
        }

        let viewController = MessageCenterViewControllerFactory.make(
            theme: theme,
            predicate: Airship.messageCenter.predicate,
            controller: self.controller
        ) {
            cancellable.cancel()
        }

        window?.isHidden = false
        window?.windowLevel = .alert
        window?.makeKeyAndVisible()
        window?.rootViewController = viewController

        return cancellable
    }

    private func openMessageView(
        scene: UIWindowScene,
        messageID: String,
        theme: MessageCenterTheme?
    ) -> any AirshipMainActorCancellable {
        var window: UIWindow? = AirshipWindowFactory.shared.makeWindow(windowScene: scene)

        let cancellable = AirshipMainActorCancellableBlock {
            window?.windowLevel = .normal
            window?.isHidden = true
            window = nil
        }

        let viewController = HostingViewController(
            rootView: NavigationStack {
                MessageCenterMessageViewWithNavigation(
                    messageID: messageID,
                ) {
                    cancellable.cancel()
                }
                .messageCenterTheme(theme ?? MessageCenterTheme())
            }
        )

        window?.isHidden = false
        window?.windowLevel = .alert
        window?.makeKeyAndVisible()
        window?.rootViewController = viewController

        return cancellable
    }
}

private class HostingViewController<Content>: UIHostingController<Content>
where Content: View {

    override init(rootView: Content) {
        super.init(rootView: rootView)
        self.view.backgroundColor = .clear
    }

    @objc
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


extension String {
    var airshipLocalizedString: String {
        return AirshipLocalizationUtils.localizedString(
            self,
            withTable: "UrbanAirship",
            moduleBundle: AirshipCoreResources.bundle
        ) ?? self
    }
}
