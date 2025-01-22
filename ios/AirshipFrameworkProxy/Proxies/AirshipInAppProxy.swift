/* Copyright Urban Airship and Contributors */

import Foundation

#if canImport(AirshipKit)
import AirshipKit
#elseif canImport(AirshipCore)
import AirshipCore
import AirshipAutomation
#endif

public final class AirshipInAppProxy: Sendable {

    private let inAppProvider: @Sendable () throws -> InAppAutomation
    private var inApp: InAppAutomation {
        get throws { try inAppProvider() }
    }

    init(inAppProvider: @Sendable @escaping () throws -> InAppAutomation) {
        self.inAppProvider = inAppProvider
    }

    @MainActor
    public func isPaused() throws -> Bool {
        return try self.inApp.isPaused
    }

    @objc
    @MainActor
    public func setPaused(_ paused: Bool) throws {
        try self.inApp.isPaused = paused
    }

    @MainActor
    public func getDisplayInterval() throws -> Int {
        return Int(try self.inApp.inAppMessaging.displayInterval * 1000)
    }

    @MainActor
    public func setDisplayInterval(milliseconds: Int) throws {
        let seconds = Double(milliseconds)/1000.0
        try self.inApp.inAppMessaging.displayInterval = seconds
    }

    public func resendLastEmbeddedEvent() {
        Task {
            await EmbeddedEventEmitter.shared.resendLastEvent()
        }
    }
}
