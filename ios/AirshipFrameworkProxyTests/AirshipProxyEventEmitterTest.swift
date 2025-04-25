import XCTest
import AirshipKit
@testable import AirshipFrameworkProxy

@MainActor
final class AirshipProxyEventEmitterTest: XCTestCase {

    private let emitter = AirshipProxyEventEmitter()


    func testProcessPendingOrder() async {
        emitter.addEvent(TestEvent(type: .channelCreated))
        emitter.addEvent(TestEvent(type: .deepLinkReceived))
        emitter.addEvent(TestEvent(type: .channelCreated))

        var hasEvents = emitter.hasAnyEvents()
        XCTAssertTrue(hasEvents)

        var order: [AirshipProxyEventType] = []
        emitter.processPendingEvents(type: nil) { event in
            order.append(event.type)
            return true
        }

        XCTAssertEqual(order, [.channelCreated, .deepLinkReceived, .channelCreated])

        hasEvents = emitter.hasAnyEvents()
        XCTAssertFalse(hasEvents)
    }
}

fileprivate struct TestEvent: AirshipProxyEvent {
    typealias T = AirshipJSON

    var type: AirshipProxyEventType
    var body: AirshipJSON  = .bool(true)
}

