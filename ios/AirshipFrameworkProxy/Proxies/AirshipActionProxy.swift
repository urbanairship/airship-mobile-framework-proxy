/* Copyright Urban Airship and Contributors */

import Foundation
import AirshipKit

public enum AirshipActionProxyError: Error {
    case actionNotFound
    case actionError(Error?)
    case actionRejectedArguments
}

public class AirshipActionProxy: NSObject {

    private let actionRunnerProvider: () throws -> AirshipActionRunnerProtocol
    private var actionRunner: AirshipActionRunnerProtocol {
        get throws { try actionRunnerProvider() }
    }

    init(actionRunnerProvider: @escaping () throws -> AirshipActionRunnerProtocol) {
        self.actionRunnerProvider = actionRunnerProvider
    }

    public func runAction(
        _ name: String,
        value: AirshipJSON?
    ) async throws -> Any? {
        let result = try await self.actionRunner.runAction(
            name,
            value: value
        )

        switch (result) {
        case .completed(let actionResult):
            return actionResult
        case .actionNotFound:
            throw AirshipActionProxyError.actionNotFound
        case .argumentsRejected:
            throw AirshipActionProxyError.actionRejectedArguments
        case .error(let actionError):
            throw AirshipActionProxyError.actionError(actionError)
        }
    }
}

protocol AirshipActionRunnerProtocol: AnyObject {
    func runAction(_ name: String, value: AirshipJSON?) async -> ActionResult
}


class AirshipActionRunner: AirshipActionRunnerProtocol {
    func runAction(_ name: String, value: AirshipJSON?) async -> ActionResult {
        return await ActionRunner.run(
            actionName: name,
            arguments: ActionArguments(
                value: value ?? .null
            )
        )
    }
}
