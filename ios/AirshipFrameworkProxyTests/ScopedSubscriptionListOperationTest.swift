import XCTest

@testable import AirshipFrameworkProxy
import AirshipKit

class ScopedSubscriptionListOperationTest: XCTestCase {

    func testParse() throws {
        let json = """
            {
                "listId": "some list",
                "action": "subscribe",
                "scope": "app"
            }
        """


        let parsed = try JSONDecoder().decode(ScopedSubscriptionListOperation.self, from: json.data(using: .utf8)!)

        let expected = ScopedSubscriptionListOperation(
            action: .subscribe,
            listID: "some list",
            scope: .app
        )

        XCTAssertEqual(expected, parsed)
    }

    func testParseInvalidScope() throws {
        let json = """
           {
               "listId": "some list",
               "action": "subscribe",
               "scope": "invalid"
           }
        """

        do {
            let _ = try JSONDecoder().decode(ScopedSubscriptionListOperation.self, from: json.data(using: .utf8)!)
            XCTFail("should throw")
        } catch {}
    }

}
