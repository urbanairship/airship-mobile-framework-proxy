/* Copyright Urban Airship and Contributors */

import Foundation

#if canImport(AirshipKit)
public import AirshipKit
#elseif canImport(AirshipCore)
public import AirshipCore
#endif

public enum AirshipActionProxyError: Error {
    case actionNotFound
    case actionError((any Error)?)
    case actionRejectedArguments
}

public final class AirshipActionProxy: Sendable {

    private let actionRunnerProvider: @Sendable () throws -> any AirshipActionRunnerProtocol
    private var actionRunner: any AirshipActionRunnerProtocol {
        get throws { try actionRunnerProvider() }
    }

    init(actionRunnerProvider: @Sendable @escaping () throws -> any AirshipActionRunnerProtocol) {
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
        @unknown default:
            throw AirshipErrors.error(
                "Unknown ActionResult \(result)"
            )
        }
    }
}

protocol AirshipActionRunnerProtocol: AnyObject, Sendable {
    func runAction(_ name: String, value: AirshipJSON?) async -> ActionResult
}


final class AirshipActionRunner: AirshipActionRunnerProtocol {
    func runAction(_ name: String, value: AirshipJSON?) async -> ActionResult {
        return await ActionRunner.run(
            actionName: name,
            arguments: ActionArguments(
                value: value ?? .null
            )
        )
    }
}
