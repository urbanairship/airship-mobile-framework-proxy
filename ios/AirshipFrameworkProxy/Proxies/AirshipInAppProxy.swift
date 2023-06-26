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

    public func isPaused() throws -> Bool {
        return try self.inApp.isPaused
    }

    @objc
    public func setPaused(_ paused: Bool) throws {
        try self.inApp.isPaused = paused
    }

    public func getDisplayInterval() throws -> Int {
        return Int(try self.inApp.displayInterval * 1000)
    }

    public func setDisplayInterval(_ displayInterval: Int) throws {
        let seconds = Double(displayInterval)/1000.0
        try self.inApp.displayInterval = seconds
    }
}

protocol AirshipInAppProtocol: AnyObject {
    var displayInterval: TimeInterval { get set }
    var isPaused: Bool { get set }
}

extension InAppAutomation : AirshipInAppProtocol {
    var displayInterval: TimeInterval {
        get {
            self.inAppMessageManager.displayInterval
        }
        set {
            self.inAppMessageManager.displayInterval = newValue
        }
    }
}
