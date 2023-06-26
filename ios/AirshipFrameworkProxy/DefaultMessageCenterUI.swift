import AirshipKit
import Foundation

public class DefaultMessageCenterUI {
    static let shared: DefaultMessageCenterUI = DefaultMessageCenterUI()
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
