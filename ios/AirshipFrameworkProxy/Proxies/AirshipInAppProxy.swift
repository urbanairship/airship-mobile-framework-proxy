/* Copyright Urban Airship and Contributors */

import Foundation
import AirshipKit

public class AirshipInAppProxy {

    private let inAppProvider: () throws -> AirshipInAppProtocol
    private var inApp: AirshipInAppProtocol {
        get throws { try inAppProvider() }
    }

    init(inAppProvider: @escaping () throws -> any AirshipInAppProtocol) {
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
        return Int(try self.inApp.displayInterval * 1000)
    }

    @MainActor
    public func setDisplayInterval(_ displayInterval: Int) throws {
        let seconds = Double(displayInterval)/1000.0
        try self.inApp.displayInterval = seconds
    }
}

protocol AirshipInAppProtocol: AnyObject {
    @MainActor
    var displayInterval: TimeInterval { get set }
    @MainActor
    var isPaused: Bool { get set }
}

extension InAppAutomation : AirshipInAppProtocol {
    @MainActor
    var displayInterval: TimeInterval {
        get {
            self.inAppMessaging.displayInterval
        }
        set {
            self.inAppMessaging.displayInterval = newValue
        }
    }
}
