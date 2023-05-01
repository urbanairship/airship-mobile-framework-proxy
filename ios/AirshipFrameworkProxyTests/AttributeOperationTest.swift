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

    func testApplyRemove() throws {
        let editor = TestEditor()
        let operation = AttributeOperation(action: .removeAttribute, attribute: "some attribute", value: nil, valueType: nil)
        operation.apply(editor: editor)

        XCTAssertEqual(editor.removes, ["some attribute"])
        XCTAssertTrue(editor.sets.isEmpty)
    }

    func testApplySetString() throws {
        let editor = TestEditor()
        let operation = AttributeOperation(
            action: .setAttribute,
            attribute: "some attribute",
            value: .string("neat"),
            valueType: .string
        )

        operation.apply(editor: editor)
        XCTAssertEqual(editor.sets, ["some attribute": "neat"])
        XCTAssertTrue(editor.removes.isEmpty)
    }

    func testApplyNumber() throws {
        let editor = TestEditor()
        let operation = AttributeOperation(
            action: .setAttribute,
            attribute: "some attribute",
            value: .number(100.1),
            valueType: .number
        )

        operation.apply(editor: editor)
        XCTAssertEqual(editor.sets, ["some attribute": 100.1])
        XCTAssertTrue(editor.removes.isEmpty)
    }

    func testApplyDate() throws {
        let editor = TestEditor()
        let operation = AttributeOperation(
            action: .setAttribute,
            attribute: "some attribute",
            value: .number(1682681877000),
            valueType: .date
        )

        operation.apply(editor: editor)
        XCTAssertEqual(editor.sets, ["some attribute": Date(timeIntervalSince1970: 1682681877)])
        XCTAssertTrue(editor.removes.isEmpty)
    }

    func testApplyInvalidString() throws {
        let editor = TestEditor()


        AttributeOperation(
            action: .setAttribute,
            attribute: "number string attribute",
            value: .number(10.0),
            valueType: .string
        ).apply(editor: editor)

        AttributeOperation(
            action: .setAttribute,
            attribute: "null string attribute",
            value: .null,
            valueType: .string
        ).apply(editor: editor)


        AttributeOperation(
            action: .setAttribute,
            attribute: "dictionary string attribute",
            value: try! AirshipJSON.wrap(["cool": "beans"]),
            valueType: .string
        ).apply(editor: editor)


        XCTAssertTrue(editor.sets.isEmpty)
        XCTAssertTrue(editor.removes.isEmpty)
    }

    func testApplyInvalidNumber() throws {
        let editor = TestEditor()


        AttributeOperation(
            action: .setAttribute,
            attribute: "string number attribute",
            value: .string("hello"),
            valueType: .number
        ).apply(editor: editor)

        AttributeOperation(
            action: .setAttribute,
            attribute: "null number attribute",
            value: .null,
            valueType: .number
        ).apply(editor: editor)


        AttributeOperation(
            action: .setAttribute,
            attribute: "dictionary number attribute",
            value: try! AirshipJSON.wrap(["cool": "beans"]),
            valueType: .number
        ).apply(editor: editor)


        XCTAssertTrue(editor.sets.isEmpty)
        XCTAssertTrue(editor.removes.isEmpty)
    }

    func testApplyInvalidDate() throws {
        let editor = TestEditor()


        AttributeOperation(
            action: .setAttribute,
            attribute: "string date attribute",
            value: .string("1682681877000"),
            valueType: .date
        ).apply(editor: editor)

        AttributeOperation(
            action: .setAttribute,
            attribute: "null date attribute",
            value: .null,
            valueType: .date
        ).apply(editor: editor)


        AttributeOperation(
            action: .setAttribute,
            attribute: "dictionary date attribute",
            value: try! AirshipJSON.wrap(["cool": "beans"]),
            valueType: .date
        ).apply(editor: editor)


        XCTAssertTrue(editor.sets.isEmpty)
        XCTAssertTrue(editor.removes.isEmpty)
    }
}

fileprivate class TestEditor: AttributeOperationEditor {

    var removes: Set<String> = Set()
    var sets: [String: AnyHashable] = [:]

    func remove(_ attribute: String) {
        removes.insert(attribute)
        sets[attribute] = nil
    }

    func set(date: Date, attribute: String) {
        removes.remove(attribute)
        sets[attribute] = date
    }

    func set(double: Double, attribute: String) {
        removes.remove(attribute)
        sets[attribute] = double
    }

    func set(string: String, attribute: String) {
        removes.remove(attribute)
        sets[attribute] = string
    }
}
