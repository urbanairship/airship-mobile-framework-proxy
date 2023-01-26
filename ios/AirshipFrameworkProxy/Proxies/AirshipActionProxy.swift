/* Copyright Urban Airship and Contributors */

import Foundation
import AirshipKit

public enum AirshipActionProxyError: Error {
    case actionNotFound
    case actionError(Error?)
    case actionRejectedArguments
}


@objc
public class AirshipActionProxy: NSObject {

    private let actionRunnerProvider: () throws -> AirshipActionRunnerProtocol
    private var actionRunner: AirshipActionRunnerProtocol {
        get throws { try actionRunnerProvider() }
    }

    init(actionRunnerProvider: @escaping () throws -> AirshipActionRunnerProtocol) {
        self.actionRunnerProvider = actionRunnerProvider
    }

    @objc
    public func runAction(
        _ name: String,
        actionValue value: Any?
    ) async throws -> Any? {
        let actionResult = try await self.actionRunner.runAction(
            name,
            value: value
        )

        switch (actionResult.status) {
        case .completed:
            return actionResult.value
        case .actionNotFound:
            throw AirshipActionProxyError.actionNotFound
        case .argumentsRejected:
            throw AirshipActionProxyError.actionRejectedArguments
        case .error: fallthrough
        @unknown default:
            throw AirshipActionProxyError.actionError(actionResult.error)
        }
    }
}

protocol AirshipActionRunnerProtocol: AnyObject {
    func runAction(_ name: String, value: Any?) async -> ActionResult
}


class AirshipActionRunner: AirshipActionRunnerProtocol {
    func runAction(_ name: String, value: Any?) async -> ActionResult {
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
