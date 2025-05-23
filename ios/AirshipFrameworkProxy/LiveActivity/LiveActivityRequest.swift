/* Copyright Airship and Contributors */

import Foundation

#if canImport(AirshipKit)
public import AirshipKit
#elseif canImport(AirshipCore)
public import AirshipCore
#endif

public struct LiveActivityRequest: Sendable, Equatable {

    public struct List: Sendable, Equatable, Codable {
        public var attributesType: String


        public init(attributesType: String) {
            self.attributesType = attributesType
        }
    }

    public struct Update: Sendable, Equatable, Codable {
        public var activityID: String
        public var content: LiveActivityContent

        enum CodingKeys: String, CodingKey {
            case activityID = "activityId"
            case content
        }


        public init(
            activityID: String,
            content: LiveActivityContent
        ) {
            self.activityID = activityID
            self.content = content
        }
    }

    public struct End: Sendable, Equatable, Codable {
        public var activityID: String
        public var content: LiveActivityContent?
        public var dismissalPolicy: DismissalPolicy?

        enum CodingKeys: String, CodingKey {
            case activityID = "activityId"
            case content
            case dismissalPolicy
        }

        public init(
            activityID: String,
            content: LiveActivityContent? = nil,
            dismissalPolicy: DismissalPolicy? = nil
        ) {
            self.activityID = activityID
            self.content = content
            self.dismissalPolicy = dismissalPolicy
        }
    }

    public struct Start: Sendable, Equatable, Codable {
        public var attributesType: String
        public var content: LiveActivityContent
        public var attributes: AirshipJSON

        enum CodingKeys: String, CodingKey {
            case attributesType
            case content
            case attributes
        }

        public init(
            attributesType: String,
            content: LiveActivityContent,
            attributes: AirshipJSON
        ) {
            self.attributesType = attributesType
            self.content = content
            self.attributes = attributes
        }
    }

    public enum DismissalPolicy: Sendable, Equatable, Codable {
        case immediate
        case `default`
        case after(date: Date)

        enum CodingKeys: String, CodingKey {
            case type
            case date
        }

        private enum DismissalType: String, Codable {
            case immediate
            case `default` = "default"
            case after
        }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let type = try container.decode(DismissalType.self, forKey: .type)
            switch (type) {
            case .after:
                let dateString = try container.decode(String.self, forKey: .date)
                guard let date = AirshipDateFormatter.date(fromISOString: dateString) else {
                    throw AirshipErrors.error("Invalid date format \(dateString)")
                }
                self = .after(date: date)
            case .immediate:
                self = .immediate
            case .default:
                self = .default
            }
        }

        public func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            switch (self) {
            case .after(let date):
                try container.encode(DismissalType.after, forKey: .type)
                try container.encode(AirshipDateFormatter.string(fromDate: date, format: .iso), forKey: .date)
            case .immediate:
                try container.encode(DismissalType.immediate, forKey: .type)
            case .default:
                try container.encode(DismissalType.default, forKey: .type)
            }
        }
    }
}


