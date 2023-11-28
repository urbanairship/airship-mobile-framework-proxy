import Foundation
import Combine

public actor AirshipProxyEventEmitter {
    private let updateContinuation: AsyncStream<AirshipProxyEvent>.Continuation
    public let pendingEventAdded: AsyncStream<AirshipProxyEvent>
    public static let shared = AirshipProxyEventEmitter()
    private nonisolated let eventSubject = PassthroughSubject<AirshipProxyEvent, Never>()

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

    private var eventMap: [AirshipProxyEventType: [AirshipProxyEvent]] = [:]

    public func hasEvent(type: AirshipProxyEventType) -> Bool {
        return eventMap[type]?.isEmpty == false
    }

    public func hasAnyEvents() -> Bool {
        return eventMap.values.contains { events in
            !events.isEmpty
        }
    }

    public func takePendingEvents(
        type: AirshipProxyEventType
    ) -> [AirshipProxyEvent] {
        let result = eventMap[type]
        eventMap[type] = []
        return result ?? []
    }

    public func processPendingEvents(
        type: AirshipProxyEventType?,
        handler: (AirshipProxyEvent) -> Bool
    ) {
        var types: [AirshipProxyEventType]!
        if let type = type {
            types = [type]
        } else {
            types = AirshipProxyEventType.allCases
        }

        for type in types {
            let result = eventMap[type] ?? []
            eventMap[type] = result.filter { event in
                return !handler(event)
            }
        }
    }

    func addEvent(_ event: AirshipProxyEvent) {
        if eventMap[event.type] == nil {
            eventMap[event.type] = []
        }
        eventMap[event.type]?.append(event)
        updateContinuation.yield(event)
        eventSubject.send(event)
    }
}
