import AirshipKit
import Foundation
import UIKit
import SwiftUI

public class DefaultMessageCenterUI {
    static let shared: DefaultMessageCenterUI = DefaultMessageCenterUI()
    private var currentDisplay: AirshipMainActorCancellable?
    private var controller: MessageCenterController = MessageCenterController()

    @MainActor
    func dismiss() {
        self.currentDisplay?.cancel()
    }

    @MainActor
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
            theme: MessageCenter.shared.theme
        )
    }

    @MainActor
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
            theme: MessageCenter.shared.theme
        )
    }

    @MainActor
    private func open(
        scene: UIWindowScene,
        theme: MessageCenterTheme?
    ) -> AirshipMainActorCancellable {
        var window: UIWindow? = UIWindow(windowScene: scene)

        let cancellable = AirshipMainActorCancellableBlock {
            window?.windowLevel = .normal
            window?.isHidden = true
            window = nil
        }

        let viewController = MessageCenterViewControllerFactory.make(
            theme: theme,
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

    @MainActor
    private func openMessageView(
        scene: UIWindowScene,
        messageID: String,
        theme: MessageCenterTheme?
    ) -> AirshipMainActorCancellable {
        var window: UIWindow? = UIWindow(windowScene: scene)

        let cancellable = AirshipMainActorCancellableBlock {
            window?.windowLevel = .normal
            window?.isHidden = true
            window = nil
        }

        let theme = theme ?? MessageCenterTheme()
        let viewController = HostingViewController(
            rootView: StandaloneMessageView(
                dismissAction: {
                    cancellable.cancel()

                }, 
                content: {
                    MessageCenterMessageView(
                        messageID: messageID,
                        title: nil
                    ) {
                        cancellable.cancel()
                    }
                    .messageCenterTheme(theme)
                }
            )
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

struct StandaloneMessageView<Content: View>: View  {
    @Environment(\.airshipMessageCenterTheme)
    private var theme

    let dismissAction: () -> Void

    @ViewBuilder
    private func makeBackButton() -> some View {
        Button(action: {
            self.dismissAction()
        }) {
            Image(systemName: "chevron.backward")
                .scaleEffect(0.68)
                .font(Font.title.weight(.medium))
                .foregroundColor(theme.backButtonColor)
        }
    }

    let content: () -> Content

    @ViewBuilder
    func makeContent() -> some View {
        let content = content()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    makeBackButton()
                }
            }
        if #available(iOS 16.0, *) {
            NavigationStack {
                content
            }
        } else {
            NavigationView {
                content
            }
            .navigationViewStyle(.stack)
        }
    }

    var body: some View {
        makeContent()
            .navigationTitle(
                theme.navigationBarTitle ?? "ua_message_center_title".airshipLocalizedString
            )
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
