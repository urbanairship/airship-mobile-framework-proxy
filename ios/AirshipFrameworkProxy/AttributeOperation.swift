/* Copyright Airship and Contributors */

import Foundation
import AirshipKit

public struct AttributeOperation: Decodable {
    enum Action: String, Decodable {
        case setAttribute = "set"
        case removeAttribute = "remove"
    }

    enum ValueType: String, Decodable {
        case string
        case number
        case date
    }

    let action: Action
    let attribute: String
    let value: AirshipJSON?
    let valueType: ValueType?

    private enum CodingKeys: String, CodingKey {
        case action = "action"
        case attribute = "key"
        case value = "value"
        case valueType = "type"
    }

    func apply(editor: AttributesEditor) {
        guard attribute.isEmpty else {
            AirshipLogger.error("Invalid attribute operation: \(self)")
            return
        }

        switch(action) {
        case .removeAttribute:
            editor.remove(attribute)
        case .setAttribute:
            switch(valueType) {
            case .number:
                if let value = value?.unWrap() as? Double {
                    editor.set(double: value, attribute: attribute)
                } else {
                    AirshipLogger.error("Failed to parse double: \(self)")
                }
            case .string:
                if let value = value?.unWrap() as? String {
                    editor.set(string: value, attribute: attribute)
                } else {
                    AirshipLogger.error("Failed to parse string: \(self)")
                }
            case .date:
                if let value = value?.unWrap() as? Double {
                    editor.set(
                        date: Date(timeIntervalSince1970: value),
                        attribute: attribute
                    )
                } else {
                    AirshipLogger.error("Failed to parse date: \(self)")
                }
            case .none:
                AirshipLogger.error("Missing attribute value: \(self)")
            }
        }
    }
}
