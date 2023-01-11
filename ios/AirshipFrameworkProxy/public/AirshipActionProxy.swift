/* Copyright Urban Airship and Contributors */

import Foundation
import AirshipKit

public enum AirshipActionProxyError: Error {
    case notFound
    case error(Error)
    case rejectedArguments
    case other
}

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
    ) async throws -> Any? {
        let actionResult = try await self.actionRunner.runAction(
            name,
            value: value
        )

        switch (actionResult.status) {
        case .completed:
            return actionResult.value
        case .actionNotFound:
            throw AirshipActionProxyError.notFound
        case .argumentsRejected:
            throw AirshipActionProxyError.rejectedArguments
        case .error: fallthrough
        @unknown default:
            if let error = actionResult.error {
                throw AirshipActionProxyError.error(error)
            } else {
                throw AirshipActionProxyError.other
            }
        }
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
