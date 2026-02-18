import Foundation
@preconcurrency public import Combine

#if canImport(AirshipKit)
import AirshipKit
#elseif canImport(AirshipCore)
import AirshipCore
#endif

@MainActor
public final class AirshipProxyEventEmitter {
    private let updateContinuation: AsyncStream<any AirshipProxyEvent>.Continuation
    public let pendingEventAdded: AsyncStream<any AirshipProxyEvent>
    public static let shared = AirshipProxyEventEmitter()
    private nonisolated let eventSubject = PassthroughSubject<any AirshipProxyEvent, Never>()

    private var pendingEvents: [any AirshipProxyEvent] = []

    public nonisolated var pendingEventPublisher: AnyPublisher<any AirshipProxyEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }

    init() {
        var escapee: AsyncStream<any AirshipProxyEvent>.Continuation!
        self.pendingEventAdded = AsyncStream { continuation in
            escapee = continuation
        }
        self.updateContinuation = escapee
    }

    public func hasEvent(type: AirshipProxyEventType) -> Bool {
        let has = pendingEvents.contains { $0.type == type }
        AirshipLogger.trace("hasEvent type=\(type), hasMatching=\(has), pendingCount=\(pendingEvents.count)")
        return has
    }

    public func hasAnyEvents() -> Bool {
        let has = !pendingEvents.isEmpty
        AirshipLogger.trace("hasAnyEvents hasEvents=\(has), pendingCount=\(pendingEvents.count)")
        return has
    }

    public func takePendingEvents(
        type: AirshipProxyEventType
    ) -> [any AirshipProxyEvent] {

        var result: [any AirshipProxyEvent] = []
        
        pendingEvents.removeAll(where: { event in
            if event.type == type {
                result.append(event)
                return true
            } else {
                return false
            }
        })

        let takenDescriptions = result.map { "\($0.type): \(String(describing: $0))" }
        let remainingDescriptions = pendingEvents.map { "\($0.type): \(String(describing: $0))" }
        AirshipLogger.trace("takePendingEvents type=\(type), taken=\(result.count) [\(takenDescriptions.joined(separator: ", "))], remainingPending=\(pendingEvents.count) [\(remainingDescriptions.joined(separator: ", "))]")
        return result
    }

    public func processPendingEvents(
        type: AirshipProxyEventType?,
        handler: (any AirshipProxyEvent) -> Bool
    ) {
        let types: Set<AirshipProxyEventType> = if let type = type {
            Set([type])
        } else {
            Set(AirshipProxyEventType.allCases)
        }

        let before = pendingEvents.count
        pendingEvents.removeAll(where: { event in
            if types.contains(event.type) {
                return handler(event)
            } else {
                return false
            }
        })
        let after = pendingEvents.count
        let processed = before - after
        AirshipLogger.trace("processPendingEvents type=\(type.map { String(describing: $0) } ?? "all"), processed=\(processed), pendingBefore=\(before), pendingAfter=\(after)")
    }

    func addEvent(_ event: any AirshipProxyEvent, replacePending: Bool = false) {
        if replacePending {
            let before = pendingEvents.count
            pendingEvents.removeAll { event.type == $0.type }
            let removed = before - pendingEvents.count
            AirshipLogger.trace("addEvent replacePending=true, type=\(event.type), removed=\(removed), pendingCount=\(pendingEvents.count)")
        }
        pendingEvents.append(event)
        AirshipLogger.trace("addEvent emitted event: type=\(event.type), replacePending=\(replacePending)")
        updateContinuation.yield(event)
        eventSubject.send(event)
    }
}
