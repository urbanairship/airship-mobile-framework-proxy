import Foundation
@preconcurrency public import Combine

public actor AirshipProxyEventEmitter {
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
        return pendingEvents.contains { event in
            event.type == type
        }
    }

    public func hasAnyEvents() -> Bool {
        return !pendingEvents.isEmpty
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

        pendingEvents.removeAll(where: { event in
            if types.contains(event.type) {
                return handler(event)
            } else {
                return false
            }
        })
    }

    func addEvent(_ event: any AirshipProxyEvent, replacePending: Bool = false) {
        if replacePending {
            self.pendingEvents.removeAll { event.type == $0.type }
        }
        self.pendingEvents.append(event)
        updateContinuation.yield(event)
        eventSubject.send(event)
    }
}
