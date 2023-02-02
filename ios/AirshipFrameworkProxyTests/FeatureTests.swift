import XCTest
@testable import AirshipFrameworkProxy
import AirshipKit

class FeatureTests: XCTestCase {

    func testFeaturesEncoding() throws {
        let data = try JSONUtils.data(["push", "analytics"], options:.fragmentsAllowed)
        let fromJson = try JSONDecoder().decode(Features.self, from: data)
        XCTAssertEqual([.push, .analytics], fromJson)

        let encoded = try JSONEncoder().encode(fromJson)
        let decoded = try JSONDecoder().decode(Features.self, from: encoded)

        XCTAssertEqual(fromJson, decoded)
    }

    func testFeaturesEncodingAll() throws {
        let data = try JSONUtils.data(["all"], options:.fragmentsAllowed)
        let fromJson = try JSONDecoder().decode(Features.self, from: data)
        XCTAssertEqual(Features.all, fromJson)
    }

    func testFeaturesEncodingNone() throws {
        let data = try JSONUtils.data(["none"], options:.fragmentsAllowed)
        let fromJson = try JSONDecoder().decode(Features.self, from: data)
        XCTAssertEqual([], fromJson)
    }

    func testFeaturesEncodingEmpty() throws {
        let data = try JSONUtils.data([], options:.fragmentsAllowed)
        let fromJson = try JSONDecoder().decode(Features.self, from: data)
        XCTAssertEqual([], fromJson)
    }

    func testFeatureNameAll() throws {
        let features = Features.all
        XCTAssertEqual(
            ["push", "chat", "location", "tags_and_attributes", "message_center", "analytics", "in_app_automation", "contacts"].sorted(),
            features.names.sorted()
        )
    }

    func testFeatureNamesNone() throws {
        let features: Features = []
        XCTAssertEqual(
            [],
            features.names
        )
    }
}
