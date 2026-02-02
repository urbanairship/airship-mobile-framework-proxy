/* Copyright Urban Airship and Contributors */

import Foundation

#if canImport(AirshipKit)
import AirshipKit
#elseif canImport(AirshipCore)
import AirshipCore
import AirshipAutomation
#endif

public final class AirshipInAppProxy: Sendable {

    private let inAppProvider: @Sendable () throws -> any InAppAutomation
    private var inApp: any InAppAutomation {
        get throws { try inAppProvider() }
    }

    init(inAppProvider: @Sendable @escaping () throws -> any InAppAutomation) {
        self.inAppProvider = inAppProvider
    }

    @MainActor
    public func isPaused() throws -> Bool {
        AirshipLogger.trace("isPaused called")
        return try self.inApp.isPaused
    }

    @objc
    @MainActor
    public func setPaused(_ paused: Bool) throws {
        AirshipLogger.trace("setPaused called, paused=\(paused)")
        try self.inApp.isPaused = paused
    }

    @MainActor
    public func getDisplayInterval() throws -> Int {
        AirshipLogger.trace("getDisplayInterval called")
        return Int(try self.inApp.inAppMessaging.displayInterval * 1000)
    }

    @MainActor
    public func setDisplayInterval(milliseconds: Int) throws {
        AirshipLogger.trace("setDisplayInterval called, milliseconds=\(milliseconds)")
        let seconds = Double(milliseconds)/1000.0
        try self.inApp.inAppMessaging.displayInterval = seconds
    }

    public func resendLastEmbeddedEvent() {
        AirshipLogger.trace("resendLastEmbeddedEvent called")
        Task {
            await EmbeddedEventEmitter.shared.resendLastEvent()
        }
    }
}
