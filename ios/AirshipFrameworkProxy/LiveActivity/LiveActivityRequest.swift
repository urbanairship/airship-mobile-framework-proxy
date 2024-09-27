/* Copyright Airship and Contributors */

#if canImport(AirshipKit)
import AirshipKit
#elseif canImport(AirshipCore)
import AirshipCore
#endif

public struct LiveActivityRequest: Sendable, Equatable {

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


        enum CodingKeys: String, CodingKey {
            case activityID = "activityId"
            case typeReferenceID = "typeReferenceId"
            case content
        }


        public init(
            activityID: String,
            typeReferenceID: String,
            content: LiveActivityContent
        ) {
            self.activityID = activityID
            self.typeReferenceID = typeReferenceID
            self.content = content
        }
    }

    public struct End: Sendable, Equatable, Codable {
        public var activityID: String
        public var typeReferenceID: String
        public var content: LiveActivityContent?
        public var dismissalPolicy: DismissalPolicy?

        enum CodingKeys: String, CodingKey {
            case activityID = "activityId"
            case typeReferenceID = "typeReferenceId"
            case content
            case dismissalPolicy
        }

        public init(
            activityID: String,
            typeReferenceID: String,
            content: LiveActivityContent? = nil,
            dismissalPolicy: DismissalPolicy? = nil
        ) {
            self.activityID = activityID
            self.typeReferenceID = typeReferenceID
            self.content = content
            self.dismissalPolicy = dismissalPolicy
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


