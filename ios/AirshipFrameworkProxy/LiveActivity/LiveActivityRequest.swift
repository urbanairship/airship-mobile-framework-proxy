/* Copyright Airship and Contributors */

#if canImport(AirshipKit)
import AirshipKit
#elseif canImport(AirshipCore)
import AirshipCore
#endif

public struct LiveActivityRequest: Sendable, Equatable {

    public struct Timestamp: Codable, Sendable, Equatable, Hashable {
        public let date: Date

        public init(date: Date) {
            self.date = date
        }

        public func encode(to encoder: any Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(AirshipDateFormatter.string(fromDate: date, format: .iso))
        }

        public init(from decoder: any Decoder) throws {
            var value = try decoder.singleValueContainer().decode(String.self)
            guard let date = AirshipDateFormatter.date(fromISOString: value) else {
                throw AirshipErrors.error("Invalid date")
            }
            self.date = date
        }
    }

    public struct List: Sendable, Equatable, Codable {
        public var typeReferenceID: String

        enum CodingKeys: String, CodingKey {
            case typeReferenceID = "typeReferenceId"
        }

        public init(typeReferenceID: String) {
            self.typeReferenceID = typeReferenceID
        }
    }

    public struct Update: Sendable, Equatable, Codable {
        public var activityID: String
        public var typeReferenceID: String
        public var content: LiveActivityContent
        public var timestamp: Timestamp?


        enum CodingKeys: String, CodingKey {
            case activityID
            case typeReferenceID = "typeReferenceId"
            case content
            case timestamp
        }


        public init(
            activityID: String,
            typeReferenceID: String,
            content: LiveActivityContent,
            timestamp: Timestamp? = nil
        ) {
            self.activityID = activityID
            self.typeReferenceID = typeReferenceID
            self.content = content
            self.timestamp = timestamp
        }
    }

    public struct End: Sendable, Equatable, Codable {
        public var activityID: String
        public var typeReferenceID: String
        public var content: LiveActivityContent?
        public var dismissalPolicy: DismissalPolicy?
        public var timestamp: Timestamp?

        enum CodingKeys: String, CodingKey {
            case activityID
            case typeReferenceID = "typeReferenceId"
            case content
            case dismissalPolicy
            case timestamp
        }

        public init(
            activityID: String,
            typeReferenceID: String,
            content: LiveActivityContent? = nil,
            dismissalPolicy: DismissalPolicy? = nil,
            timestamp: Timestamp? = nil
        ) {
            self.activityID = activityID
            self.typeReferenceID = typeReferenceID
            self.content = content
            self.dismissalPolicy = dismissalPolicy
            self.timestamp = timestamp
        }
    }

    public struct Create: Sendable, Equatable, Codable {
        public var typeReferenceID: String
        public var content: LiveActivityContent
        public var attributes: AirshipJSON

        enum CodingKeys: String, CodingKey {
            case typeReferenceID = "typeReferenceId"
            case content
            case attributes
        }
        public init(
            typeReferenceID: String,
            content: LiveActivityContent,
            attributes: AirshipJSON
        ) {
            self.typeReferenceID = typeReferenceID
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
                self = .after(date: try container.decode(Date.self, forKey: .date))
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
                try container.encode(date, forKey: .date)
            case .immediate:
                try container.encode(DismissalType.immediate, forKey: .type)
            case .default:
                try container.encode(DismissalType.default, forKey: .type)
            }
        }
    }
}


