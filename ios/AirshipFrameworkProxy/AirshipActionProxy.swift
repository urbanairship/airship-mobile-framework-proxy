/* Copyright Urban Airship and Contributors */

import Foundation
import AirshipKit

public class AirshipActionProxy {

    private let actionRunnerProvider: () throws -> AirshipActionRunnerProtocol
    private var actionRunner: AirshipActionRunnerProtocol {
        get throws { try actionRunnerProvider() }
    }

    init(actionRunnerProvider: @escaping () throws -> AirshipActionRunnerProtocol) {
        self.actionRunnerProvider = actionRunnerProvider
    }

    public func runAction(
        _ name: String,
        actionValue value: Any
    ) async throws -> ActionResult {
        return try await self.actionRunner.runAction(
            name,
            value: value
        )
    }
}

protocol AirshipActionRunnerProtocol: AnyObject {
    func runAction(_ name: String, value: Any) async -> ActionResult
}


class AirshipActionRunner: AirshipActionRunnerProtocol {
    func runAction(_ name: String, value: Any) async -> ActionResult {
        return await withCheckedContinuation { continuation in
            ActionRunner.run(
                name,
                value: value,
                situation: Situation.manualInvocation
            ) { actionResult in
                continuation.resume(returning: actionResult)
            }
        }
    }
}
