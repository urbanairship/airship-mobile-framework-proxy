import Testing

@testable import AirshipFrameworkProxy
import AirshipKit

struct AttributeOperationTest {
    private let editor = TestEditor()

    @Test
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

        assert(expected == parsed)
    }

    @Test
    func testRemoveJSON() throws {
        let json = """
            {
                "key": "some attribute",
                "instance_id": "some instance id",
                "action": "remove"
            }
        """

        let parsed = try JSONDecoder().decode(AttributeOperation.self, from: json.data(using: .utf8)!)

        let expected = AttributeOperation(
            action: .removeAttribute,
            attribute: "some attribute",
            value: nil,
            valueType: nil,
            instanceID: "some instance id"
        )

        assert(expected == parsed)
    }

    @Test
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
            attribute: "some attribute",
            value: try AirshipJSON.wrap(1682681877000),
            valueType: .date
        )

        assert(expected == parsed)
    }

    @Test
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

        assert(expected == parsed)
    }

    @Test
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

        assert(expected == parsed)
    }

    @Test
    func testSetJSON() throws {
        let json = """
            {
                "key": "some attribute",
                "action": "set",
                "value": {
                    "foo": "bar"
                },
                "type": "json",
                "instance_id": "some instance id"
            }
        """


        let parsed = try JSONDecoder().decode(AttributeOperation.self, from: json.data(using: .utf8)!)

        let expected = AttributeOperation(
            action: .setAttribute,
            attribute: "some attribute",
            value: AirshipJSON.object(["foo": .string("bar")]),
            valueType: .json,
            instanceID: "some instance id"
        )

        assert(expected == parsed)
    }

    @Test
    func testApplyRemove() async throws {
        let operation = AttributeOperation(
            action: .removeAttribute,
            attribute: "some attribute",
            value: nil,
            valueType: nil
        )

        try await confirmation { continuation in
            editor.onMutation = { mutation in
                assert(mutation == .remove(attribute: "some attribute"))
                continuation.confirm()
            }

            try operation.apply(editor: editor)
        }
    }

    @Test
    func testApplyRemoveJSON() async throws {
        let operation = AttributeOperation(
            action: .removeAttribute,
            attribute: "some attribute",
            value: nil,
            valueType: nil,
            instanceID: "some instance"
        )

        try await confirmation { continuation in
            editor.onMutation = { mutation in
                assert(mutation == .remove(attribute: "some attribute", instanceID: "some instance"))
                continuation.confirm()
            }

            try operation.apply(editor: editor)
        }
    }

    @Test
    func testApplyJSON() async throws {
        let operation = AttributeOperation(
            action: .setAttribute,
            attribute: "some attribute",
            value: .object(["neat": .string("story")]),
            valueType: .json,
            instanceID: "some instance",
            expirationMilliseconds: 1000
        )

        try await confirmation { continuation in
            editor.onMutation = { mutation in
                let expected = TestEditor.Mutation.set(
                    value: ["neat": AirshipJSON.string("story")],
                    attribute: "some attribute",
                    instanceID: "some instance",
                    expiration: Date(timeIntervalSince1970: 1.0)
                )
                assert(mutation == expected)
                continuation.confirm()
            }

            try operation.apply(editor: editor)
        }
    }


    @Test
    func testApplySetString() async throws {
        let operation = AttributeOperation(
            action: .setAttribute,
            attribute: "some attribute",
            value: .string("neat"),
            valueType: .string
        )

        try await confirmation { continuation in
            editor.onMutation = { mutation in
                let expected = TestEditor.Mutation.set(
                    value: "neat",
                    attribute: "some attribute"
                )
                assert(mutation == expected)
                continuation.confirm()
            }

            try operation.apply(editor: editor)
        }
    }

    @Test
    func testApplyNumber() async throws {
        let operation = AttributeOperation(
            action: .setAttribute,
            attribute: "some attribute",
            value: .number(100.1),
            valueType: .number
        )

        try await confirmation { continuation in
            editor.onMutation = { mutation in
                let expected = TestEditor.Mutation.set(
                    value: 100.1,
                    attribute: "some attribute"
                )
                assert(mutation == expected)
                continuation.confirm()
            }

            try operation.apply(editor: editor)
        }
    }

    @Test
    func testApplyDate() async throws {
        let operation = AttributeOperation(
            action: .setAttribute,
            attribute: "some attribute",
            value: .number(1682681877000),
            valueType: .date
        )

        try await confirmation { continuation in
            editor.onMutation = { mutation in
                let expected = TestEditor.Mutation.set(
                    value: Date(timeIntervalSince1970: 1682681877),
                    attribute: "some attribute"
                )
                assert(mutation == expected)
                continuation.confirm()
            }

            try operation.apply(editor: editor)
        }
    }

    @Test
    func testApplyInvalidString() throws {
        do {
            try AttributeOperation(
                action: .setAttribute,
                attribute: "number string attribute",
                value: .number(10.0),
                valueType: .string
            ).apply(editor: editor)
            assertionFailure("should throw")
        } catch {}

        do {
            try AttributeOperation(
                action: .setAttribute,
                attribute: "null string attribute",
                value: .null,
                valueType: .string
            ).apply(editor: editor)
            assertionFailure("should throw")
        } catch {}

        do {
            try AttributeOperation(
                action: .setAttribute,
                attribute: "dictionary string attribute",
                value: try! AirshipJSON.wrap(["cool": "beans"]),
                valueType: .string
            ).apply(editor: editor)
            assertionFailure("should throw")
        } catch {}
    }

    @Test
    func testApplyInvalidNumber() throws {
        do {
            try AttributeOperation(
                action: .setAttribute,
                attribute: "string number attribute",
                value: .string("hello"),
                valueType: .number
            ).apply(editor: editor)
            assertionFailure("should throw")
        } catch {}

        do {
            try AttributeOperation(
                action: .setAttribute,
                attribute: "null number attribute",
                value: .null,
                valueType: .number
            ).apply(editor: editor)
            assertionFailure("should throw")
        } catch {}


        do {
            try AttributeOperation(
                action: .setAttribute,
                attribute: "dictionary number attribute",
                value: try! AirshipJSON.wrap(["cool": "beans"]),
                valueType: .number
            ).apply(editor: editor)
            assertionFailure("should throw")
        } catch {}

    }

    @Test
    func testApplyInvalidDate() throws {
        do {
            try AttributeOperation(
                action: .setAttribute,
                attribute: "string date attribute",
                value: .string("1682681877000"),
                valueType: .date
            ).apply(editor: editor)
            assertionFailure("should throw")
        } catch {}

        do {
            try AttributeOperation(
                action: .setAttribute,
                attribute: "null date attribute",
                value: .null,
                valueType: .date
            ).apply(editor: editor)
            assertionFailure("should throw")
        } catch {}


        do {
            try AttributeOperation(
                action: .setAttribute,
                attribute: "dictionary date attribute",
                value: try! AirshipJSON.wrap(["cool": "beans"]),
                valueType: .date
            ).apply(editor: editor)
        } catch {}
    }
}

fileprivate class TestEditor: AttributeOperationEditor {
    enum Mutation: Equatable, Hashable {
        case set(value: AnyHashable, attribute: String, instanceID: String? = nil, expiration: Date? = nil)
        case remove(attribute: String, instanceID: String? = nil)
    }

    var onMutation: ((Mutation) -> Void)? = nil

    func remove(_ attribute: String) {
        onMutation!(.remove(attribute: attribute))
    }

    func remove(attribute: String, instanceID: String) throws {
        onMutation!(.remove(attribute: attribute, instanceID: instanceID))
    }

    func set(date: Date, attribute: String) {
        onMutation!(.set(value: date, attribute: attribute))
    }

    func set(double: Double, attribute: String) {
        onMutation!(.set(value: double, attribute: attribute))
    }

    func set(string: String, attribute: String) {
        onMutation!(.set(value: string, attribute: attribute))
    }


    func set(json: [String : AirshipKit.AirshipJSON], attribute: String, instanceID: String, expiration: Date?) throws {
        onMutation!(.set(value: json, attribute: attribute, instanceID: instanceID, expiration: expiration))
    }
}
