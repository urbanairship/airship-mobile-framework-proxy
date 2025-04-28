/* Copyright Airship and Contributors */

import Foundation
#if canImport(AirshipKit)
import AirshipKit
#elseif canImport(AirshipCore)
import AirshipCore
#endif

public struct AttributeOperation: Decodable, Equatable, Sendable {
    enum Action: String, Decodable {
        case setAttribute = "set"
        case removeAttribute = "remove"
    }

    enum ValueType: String, Decodable, Sendable {
        case string
        case number
        case date
        case json
    }

    let action: Action
    let attribute: String
    let value: AirshipJSON?
    let valueType: ValueType?
    let instanceID: String?
    let expirationMilliseconds: Int?

    init(action: Action, attribute: String, value: AirshipJSON? = nil, valueType: ValueType? = nil, instanceID: String? = nil, expirationMilliseconds: Int? = nil) {
        self.action = action
        self.attribute = attribute
        self.value = value
        self.valueType = valueType
        self.instanceID = instanceID
        self.expirationMilliseconds = expirationMilliseconds
    }

    private enum CodingKeys: String, CodingKey {
        case action = "action"
        case attribute = "key"
        case value = "value"
        case valueType = "type"
        case expirationMilliseconds = "expiration_milliseconds"
        case instanceID = "instance_id"
    }

    func apply(editor: any AttributeOperationEditor) throws {
        switch(action) {
        case .removeAttribute:
            if let instanceID {
                try editor.remove(attribute: attribute, instanceID: instanceID)
            } else {
                editor.remove(attribute)
            }
        case .setAttribute:
            switch(valueType) {
            case .number:
                if let value = value?.unWrap() as? Double {
                    editor.set(double: value, attribute: attribute)
                } else {
                    throw AirshipErrors.error("Failed to parse double: \(self)")
                }
            case .string:
                if let value = value?.unWrap() as? String {
                    editor.set(string: value, attribute: attribute)
                } else {
                    throw AirshipErrors.error("Failed to parse string: \(self)")
                }
            case .date:
                if let value = value?.unWrap() as? Double {
                    editor.set(
                        date: Date(timeIntervalSince1970: value / 1000.0),
                        attribute: attribute
                    )
                } else {
                    throw AirshipErrors.error("Failed to parse date: \(self)")
                }
            case .json:
                guard let instanceID else {
                    throw AirshipErrors.error("Missing instance ID")
                }
                guard let object = value?.object else {
                    throw AirshipErrors.error("JSON attribute must be an object")
                }
                let expiration: Date? = if let expirationMilliseconds {
                    Date(timeIntervalSince1970: Double(expirationMilliseconds / 1000))
                } else {
                    nil
                }

                try editor.set(
                    json: object,
                    attribute: attribute,
                    instanceID: instanceID,
                    expiration: expiration
                )
            case .none:
                throw AirshipErrors.error("Missing attribute type: \(self)")
            }
        }
    }
}
protocol AttributeOperationEditor {
    func remove(_ attribute: String)
    func remove(attribute: String, instanceID: String) throws
    func set(date: Date, attribute: String)
    func set(double: Double, attribute: String)
    func set(string: String, attribute: String)
    func set(
        json: [String: AirshipJSON],
        attribute: String,
        instanceID: String,
        expiration: Date?
    ) throws
}

extension AttributesEditor: AttributeOperationEditor {}
