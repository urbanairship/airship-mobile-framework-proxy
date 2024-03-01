@testable import AirshipFrameworkProxy
import XCTest
import AirshipKit

final class QuietTimeSettingsTest: XCTestCase {
    func testFromDictionary() throws {
        let quietTime = QuietTimeSettings(from: ["start": "12:30", "end": "23:12"] )
        XCTAssertEqual(12, quietTime?.startHour)
        XCTAssertEqual(30, quietTime?.startMinute)
        XCTAssertEqual(23, quietTime?.endHour)
        XCTAssertEqual(12, quietTime?.endMinute)
    }

    func testInvalidQuietTime() throws {
        // Not throw
        let _ = try QuietTimeSettings(startHour: 0, startMinute: 0, endHour: 0, endMinute: 0)
        let _ = try QuietTimeSettings(startHour: 23, startMinute: 59, endHour: 23, endMinute: 59)

        assertThrows(startHour: 24, startMinute: 0, endHour: 0, endMinute: 0)
        assertThrows(startHour: 0, startMinute: 60, endHour: 0, endMinute: 0)
        assertThrows(startHour: 0, startMinute: 0, endHour: 24, endMinute: 0)
        assertThrows(startHour: 0, startMinute: 0, endHour: 0, endMinute: 60)
    }

    func assertThrows(startHour: UInt, startMinute: UInt, endHour: UInt, endMinute: UInt, line: UInt = #line) {
        do {
            let _ = try QuietTimeSettings(
                startHour: startHour,
                startMinute: startMinute,
                endHour: endHour,
                endMinute: endMinute
            )

            XCTFail("Should throw", line: line)
        } catch {}
    }
}
