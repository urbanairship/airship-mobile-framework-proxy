/* Copyright Airship and Contributors */

#if canImport(AirshipKit)
import AirshipKit
#elseif canImport(AirshipCore)
import AirshipCore
#endif

import ActivityKit

public struct LiveActivityInfo: Codable, Sendable, Equatable, Hashable {
    public var id: String
    public var typeReferenceID: String
    public var content: LiveActivityContent
    public var attributes: AirshipJSON
}

extension LiveActivityInfo {
    @available(iOS 16.1, *)
    init<T: ActivityAttributes>(
      activity: Activity<T>,
      typeReferenceID: String
    ) throws {
        self.id = activity.id
        self.typeReferenceID = typeReferenceID
        self.attributes = try AirshipJSON.wrap(activity.attributes)
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
}
