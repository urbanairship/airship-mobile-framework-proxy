import XCTest
import AirshipKit
@testable import AirshipFrameworkProxy

final class AirshipProxyEventEmitterTest: XCTestCase {

    private let emitter = AirshipProxyEventEmitter()


    func testProcessPendingOrder() async {
        await emitter.addEvent(TestEvent(type: .channelCreated))
        await emitter.addEvent(TestEvent(type: .deepLinkReceived))
        await emitter.addEvent(TestEvent(type: .channelCreated))

        var hasEvents = await emitter.hasAnyEvents()
        XCTAssertTrue(hasEvents)

        var order: [AirshipProxyEventType] = []
        await emitter.processPendingEvents(type: nil) { event in
            order.append(event.type)
            return true
        }

        XCTAssertEqual(order, [.channelCreated, .deepLinkReceived, .channelCreated])

        hasEvents = await emitter.hasAnyEvents()
        XCTAssertFalse(hasEvents)
    }
}

fileprivate struct TestEvent: AirshipProxyEvent {
    typealias T = AirshipJSON

    var type: AirshipProxyEventType
    var body: AirshipJSON  = .bool(true)
}

