import XCTest

@testable import AirshipFrameworkProxy
import AirshipKit

class TagOperationTest: XCTestCase {

    func testParseAdd() throws {
        let json = """
            {
                "tags": ["oneTag", "anotherTag", "andALastOne"],
                "operationType": "add"
            }
        """

        let parsed = try JSONDecoder().decode(TagOperation.self, from: json.data(using: .utf8)!)

        let expected = TagOperation(
            action: TagOperation.Action.addTags,
            tags: ["oneTag", "anotherTag", "andALastOne"]
        )

        XCTAssertEqual(expected, parsed)
    }
    
    func testParseRemove() throws {
        let json = """
            {
                "tags": ["oneTag", "anotherTag", "andALastOne"],
                "operationType": "remove"
            }
        """

        let parsed = try JSONDecoder().decode(TagOperation.self, from: json.data(using: .utf8)!)

        let expected = TagOperation(
            action: TagOperation.Action.removeTags,
            tags: ["oneTag", "anotherTag", "andALastOne"]
        )

        XCTAssertEqual(expected, parsed)
    }

    func testParseInvalidAction() throws {
        let json = """
           {
                "tags": ["oneTag", "anotherTag", "andALastOne"],
                "operationType": "invalid"
           }
        """

        do {
            let _ = try JSONDecoder().decode(TagOperation.self, from: json.data(using: .utf8)!)
            XCTFail("should throw")
        } catch {}
    }
    
    func testParseInvalidTags() throws {
        let json = """
           {
                "tags": "invalid",
                "operationType": "add"
           }
        """

        do {
            let _ = try JSONDecoder().decode(TagOperation.self, from: json.data(using: .utf8)!)
            XCTFail("should throw")
        } catch {}
    }
    
    func testApply() throws {
        let editor = TestEditor()
        let operation = TagOperation(
            action: TagOperation.Action.addTags,
            tags: ["oneTag", "anotherTag", "andALastOne"]
        )
        operation.apply(editor: editor)
        XCTAssertEqual(editor.currentTags, ["oneTag", "anotherTag", "andALastOne"])
        
        let nextOperation = TagOperation(
            action: TagOperation.Action.removeTags,
            tags: ["anotherTag", "andALastOne"]
        )
        nextOperation.apply(editor: editor)
        XCTAssertEqual(editor.currentTags, ["oneTag"])
    }

}

fileprivate class TestEditor: TagOperationEditor {
    var currentTags: Set<String> = Set()

    func add(_ tags: [String]) {
        for tag in tags {
            currentTags.insert(tag)
        }
    }

    func remove(_ tags: [String]) {
        for tag in tags {
            currentTags.remove(tag)
        }
    }
}
