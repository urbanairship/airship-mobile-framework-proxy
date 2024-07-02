import XCTest
@testable import AirshipFrameworkProxy
import AirshipKit

class FeatureTests: XCTestCase {

    func testFeaturesEncoding() throws {
        let data = try AirshipJSONUtils.data(["push", "analytics"], options:.fragmentsAllowed)
        let fromJson = try JSONDecoder().decode(AirshipFeature.self, from: data)
        XCTAssertEqual([.push, .analytics], fromJson)

        let encoded = try JSONEncoder().encode(fromJson)
        let decoded = try JSONDecoder().decode(AirshipFeature.self, from: encoded)

        XCTAssertEqual(fromJson, decoded)
    }

    func testFeaturesEncodingAll() throws {
        let data = try AirshipJSONUtils.data(["all"], options:.fragmentsAllowed)
        let fromJson = try JSONDecoder().decode(AirshipFeature.self, from: data)
        XCTAssertEqual(AirshipFeature.all, fromJson)
    }

    func testFeaturesEncodingNone() throws {
        let data = try AirshipJSONUtils.data(["none"], options:.fragmentsAllowed)
        let fromJson = try JSONDecoder().decode(AirshipFeature.self, from: data)
        XCTAssertEqual([], fromJson)
    }

    func testFeaturesEncodingEmpty() throws {
        let data = try AirshipJSONUtils.data([], options:.fragmentsAllowed)
        let fromJson = try JSONDecoder().decode(AirshipFeature.self, from: data)
        XCTAssertEqual([], fromJson)
    }

    func testFeatureNameAll() throws {
        let features = AirshipFeature.all
        XCTAssertEqual(
            [
                "push",
                "tags_and_attributes",
                "message_center",
                "analytics",
                "in_app_automation",
                "contacts",
                "feature_flags"
            ].sorted(),
            features.names.sorted()
        )
    }

    func testFeatureNamesNone() throws {
        let features: AirshipFeature = []
        XCTAssertEqual(
            [],
            features.names
        )
    }
}
