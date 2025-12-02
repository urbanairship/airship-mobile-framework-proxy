/* Copyright Airship and Contributors */

#if canImport(AirshipKit)
public import AirshipKit
#elseif canImport(AirshipCore)
public import AirshipCore
#endif

import ActivityKit

public struct LiveActivityInfo: Codable, Sendable, Equatable, Hashable {
    public var id: String
    public var attributesType: String
    public var state: LiveActivityState
    public var content: LiveActivityContent
    public var attributes: AirshipJSON

    enum CodingKeys: String, CodingKey {
        case id
        case attributesType
        case state
        case content
        case attributes
    }
}

public enum LiveActivityState: String, Codable, Sendable, Equatable, Hashable {
    case active
    case ended
    case dismissed
    case stale
    case unknown
    case pending
}

extension LiveActivityInfo {
    @available(iOS 16.1, *)
    init<T: ActivityAttributes>(
      activity: Activity<T>,
      attributesType: String
    ) throws {
        self.id = activity.id
        self.attributesType = attributesType
        self.attributes = try AirshipJSON.wrap(activity.attributes)
        self.state = Self.state(state: activity.activityState)
        self.content = if #available(iOS 16.2, *) {
            LiveActivityContent(
              state: try AirshipJSON.wrap(activity.content.state),
              staleDate: activity.content.staleDate,
              relevanceScore: activity.content.relevanceScore
            )
        } else {
            LiveActivityContent(
                state: try AirshipJSON.wrap(activity.contentState),
                staleDate: nil,
                relevanceScore: 0
            )
        }
    }

    @available(iOS 16.1, *)
    private static func state(state: ActivityState) -> LiveActivityState {
        return switch(state) {
        case .active: .active
        case .ended: .ended
        case .dismissed: .dismissed
        case .stale: .stale
        case .pending: .pending
        @unknown default: .unknown
        }
    }
}
