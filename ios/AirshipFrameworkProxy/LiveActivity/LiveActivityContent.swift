/* Copyright Airship and Contributors */

#if canImport(AirshipKit)
public import AirshipKit
#elseif canImport(AirshipCore)
public import AirshipCore
#endif

public struct LiveActivityContent: Sendable, Equatable, Codable, Hashable {
    public var state: AirshipJSON
    public var staleDate: Date?
    public var relevanceScore: Double
}
