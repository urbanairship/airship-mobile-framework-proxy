/* Copyright Airship and Contributors */

import XCTest
@testable import AirshipFrameworkProxy

@MainActor
final class LaunchDeepLinkTrackerTest: XCTestCase {

    func testTapWithDeepLinkStashes() async {
        let tracker = LaunchDeepLinkTracker()
        tracker.onNotificationResponse(
            userInfo: ["^d": "myapp://home"],
            isDefaultAction: true
        )
        let result = await tracker.takeLaunchDeepLink()
        XCTAssertEqual(result, "myapp://home")
    }

    func testConsumeOnce() async {
        let tracker = LaunchDeepLinkTracker()
        tracker.onNotificationResponse(
            userInfo: ["^d": "myapp://home"],
            isDefaultAction: true
        )
        _ = await tracker.takeLaunchDeepLink()
        let second = await tracker.takeLaunchDeepLink()
        XCTAssertNil(second)
    }

    func testLongActionNameKey() async {
        let tracker = LaunchDeepLinkTracker()
        tracker.onNotificationResponse(
            userInfo: ["deep_link_action": "myapp://home"],
            isDefaultAction: true
        )
        let result = await tracker.takeLaunchDeepLink()
        XCTAssertEqual(result, "myapp://home")
    }

    func testTapWithoutDeepLinkResolvesNil() async {
        let tracker = LaunchDeepLinkTracker()
        tracker.onNotificationResponse(userInfo: [:], isDefaultAction: true)
        let result = await tracker.takeLaunchDeepLink()
        XCTAssertNil(result)
    }

    func testNonDefaultActionIgnored() async {
        let tracker = LaunchDeepLinkTracker()
        tracker.onNotificationResponse(
            userInfo: ["^d": "myapp://home"],
            isDefaultAction: false
        )
        tracker.onLaunchResolved()
        let result = await tracker.takeLaunchDeepLink()
        XCTAssertNil(result)
    }

    func testWaiterResolvedByLaterTap() async {
        let tracker = LaunchDeepLinkTracker()
        let task = Task { await tracker.takeLaunchDeepLink() }
        await Task.yield()
        tracker.onNotificationResponse(
            userInfo: ["^d": "myapp://home"],
            isDefaultAction: true
        )
        let result = await task.value
        XCTAssertEqual(result, "myapp://home")
    }

    func testWaiterResolvedNilOnLaunchResolved() async {
        let tracker = LaunchDeepLinkTracker()
        let task = Task { await tracker.takeLaunchDeepLink() }
        await Task.yield()
        tracker.onLaunchResolved()
        let result = await task.value
        XCTAssertNil(result)
    }

    func testAfterResolvedReturnsNilImmediately() async {
        let tracker = LaunchDeepLinkTracker()
        tracker.onLaunchResolved()
        let result = await tracker.takeLaunchDeepLink()
        XCTAssertNil(result)
    }

    func testStaleStashReturnsNil() async {
        var now = Date()
        let tracker = LaunchDeepLinkTracker(dateProvider: { now })
        tracker.onNotificationResponse(
            userInfo: ["^d": "myapp://home"],
            isDefaultAction: true
        )
        now = now.addingTimeInterval(11.0)
        let result = await tracker.takeLaunchDeepLink()
        XCTAssertNil(result)
    }

    func testStashStillFreshReturnsLink() async {
        var now = Date()
        let tracker = LaunchDeepLinkTracker(dateProvider: { now })
        tracker.onNotificationResponse(
            userInfo: ["^d": "myapp://home"],
            isDefaultAction: true
        )
        now = now.addingTimeInterval(9.0)
        let result = await tracker.takeLaunchDeepLink()
        XCTAssertEqual(result, "myapp://home")
    }
}
