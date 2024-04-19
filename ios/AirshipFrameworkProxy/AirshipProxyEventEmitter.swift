import Foundation
import Combine

public actor AirshipProxyEventEmitter {
    private let updateContinuation: AsyncStream<AirshipProxyEvent>.Continuation
    public let pendingEventAdded: AsyncStream<AirshipProxyEvent>
    public static let shared = AirshipProxyEventEmitter()
    private nonisolated let eventSubject = PassthroughSubject<AirshipProxyEvent, Never>()

    private var pendingEvents: [AirshipProxyEvent] = []

    public nonisolated var pendingEventPublisher: AnyPublisher<AirshipProxyEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }

    init() {
        var escapee: AsyncStream<AirshipProxyEvent>.Continuation!
        self.pendingEventAdded = AsyncStream { continuation in
            escapee = continuation
        }
        self.updateContinuation = escapee
    }

    public func hasEvent(type: AirshipProxyEventType) -> Bool {
        return pendingEvents.contains { event in
            event.type == type
        }
    }

    public func hasAnyEvents() -> Bool {
        return !pendingEvents.isEmpty
    }

    public func takePendingEvents(
        type: AirshipProxyEventType
    ) -> [AirshipProxyEvent] {

        var result: [AirshipProxyEvent] = []
        
        pendingEvents.removeAll(where: { event in
            if event.type == type {
                result.append(event)
                return true
            } else {
                return false
            }
        })

        return result
    }

    public func processPendingEvents(
        type: AirshipProxyEventType?,
        handler: (AirshipProxyEvent) -> Bool
    ) {
        let types: Set<AirshipProxyEventType> = if let type = type {
            Set([type])
        } else {
            Set(AirshipProxyEventType.allCases)
        }

        pendingEvents.removeAll(where: { event in
            if types.contains(event.type) {
                return handler(event)
            } else {
                return false
            }
        })
    }

    func addEvent(_ event: AirshipProxyEvent) {
        self.pendingEvents.append(event)
        updateContinuation.yield(event)
        eventSubject.send(event)
    }
}
