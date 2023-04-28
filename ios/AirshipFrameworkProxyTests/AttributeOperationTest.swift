import XCTest

@testable import AirshipFrameworkProxy
import AirshipKit

class AttributeOperationTest: XCTestCase {

    func testRemove() throws {
        let json = """
            {
                "key": "some attribute",
                "action": "remove"
            }
        """


        let parsed = try JSONDecoder().decode(AttributeOperation.self, from: json.data(using: .utf8)!)

        let expected = AttributeOperation(
            action: .removeAttribute,
            attribute: "some attribute",
            value: nil,
            valueType: nil
        )

        XCTAssertEqual(expected, parsed)
    }

    func tesSetDate() throws {
        let json = """
            {
                "key": "some attribute",
                "action": "set",
                "value": 1682681877000,
                "type": "date"
            }
        """


        let parsed = try JSONDecoder().decode(AttributeOperation.self, from: json.data(using: .utf8)!)

        let expected = AttributeOperation(
            action: .setAttribute,
            attribute: "some-attribute",
            value: try AirshipJSON.wrap(1682681877000),
            valueType: .date
        )

        XCTAssertEqual(expected, parsed)
    }

    func testSetString() throws {
        let json = """
            {
                "key": "some attribute",
                "action": "set",
                "value": "neat",
                "type": "string"
            }
        """


        let parsed = try JSONDecoder().decode(AttributeOperation.self, from: json.data(using: .utf8)!)

        let expected = AttributeOperation(
            action: .setAttribute,
            attribute: "some attribute",
            value: AirshipJSON.string("neat"),
            valueType: .string
        )

        XCTAssertEqual(expected, parsed)
    }

    func testSetNumber() throws {
        let json = """
            {
                "key": "some attribute",
                "action": "set",
                "value": 10.4,
                "type": "number"
            }
        """


        let parsed = try JSONDecoder().decode(AttributeOperation.self, from: json.data(using: .utf8)!)

        let expected = AttributeOperation(
            action: .setAttribute,
            attribute: "some attribute",
            value: AirshipJSON.number(10.4),
            valueType: .number
        )

        XCTAssertEqual(expected, parsed)
    }

}
