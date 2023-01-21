/* Copyright Urban Airship and Contributors */

import Foundation
import AirshipKit

@objc
public class AirshipContactProxy: NSObject {

    private let contactProvider: () throws -> AirshipContactProtocol
    private var contact: AirshipContactProtocol {
        get throws { try contactProvider() }
    }

    init(contactProvider: @escaping () throws -> AirshipContactProtocol) {
        self.contactProvider = contactProvider
    }

    @objc
    public func identify(_ namedUser: String) throws {
        let namedUser = namedUser.trimmingCharacters(
            in: CharacterSet.whitespacesAndNewlines
        )

        if (!namedUser.isEmpty) {
            try self.contact.identify(namedUser)
        }
    }

    @objc
    public func reset() throws {
        try self.contact.reset()
    }

    public func getNamedUser() throws -> String? {
        return try self.contact.namedUserID
    }

    @objc(getNamedUserOrEmptyWithError:)
    public func _getNamedUser() throws -> String {
        return try getNamedUser() ?? ""
    }

    @objc
    public func getSubscriptionLists() async throws -> [String: [String]] {
        let instance = try self.contact
        return try await withCheckedThrowingContinuation { continuation in
            instance.fetchSubscriptionLists { lists, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                var converted: [String : [String]] = [:]
                for identifier in lists?.keys ?? Dictionary<String, ChannelScopes>().keys {
                    let scopes = lists?[identifier]
                    var scopesArray: [String] = []
                    if let values = scopes?.values {
                        for scope in values {
                            scopesArray.append(scope.stringValue)
                        }
                    }
                    converted[identifier] = scopesArray
                }

                continuation.resume(returning: converted)
            }
        }

    }

    @objc
    public func editTagGroups(json: Any) throws {
        let data = try JSONUtils.data(json)
        let operations = try JSONDecoder().decode(
            [TagGroupOperation].self,
            from: data
        )
        try self.editTagGroups(operations: operations)
    }

    public func editTagGroups(operations: [TagGroupOperation]) throws {
        try self.contact.editTagGroups { editor in
            operations.forEach { operation in
                operation.apply(editor: editor)
            }
        }
    }

    @objc
    public func editAttributes(json: Any) throws {
        let data = try JSONUtils.data(json)
        let operations = try JSONDecoder().decode(
            [AttributeOperation].self,
            from: data
        )
        try editAttributes(operations: operations)
    }


    public func editAttributes(operations: [AttributeOperation]) throws {
        try self.contact.editAttributes { editor in
            operations.forEach { operation in
                operation.apply(editor: editor)
            }
        }
    }

    @objc
    public func editSubscriptionLists(json: Any) throws {
        let data = try JSONUtils.data(json)
        let operations = try JSONDecoder().decode(
            [ScopedSubscriptionListOperation].self,
            from: data
        )

        try self.editSubscriptionLists(operations: operations)
    }

    public func editSubscriptionLists(
        operations: [ScopedSubscriptionListOperation]
    ) throws {
        try self.contact.editSubscriptionLists { editor in
            operations.forEach { operation in
                operation.apply(editor: editor)
            }
        }
    }
}

protocol AirshipContactProtocol: AnyObject {
    @discardableResult
    func fetchSubscriptionLists(
        completionHandler: @escaping ([String: ChannelScopes]?, Error?) -> Void) -> Disposable

    func editSubscriptionLists(_ editorBlock: (ScopedSubscriptionListEditor) -> Void)

    func editAttributes(_ editorBlock: (AttributesEditor) -> Void)

    func editTagGroups(_ editorBlock: (TagGroupsEditor) -> Void)

    func identify(_ namedUserID: String)

    func reset()

    var namedUserID: String? { get }

}

extension Contact: AirshipContactProtocol {

}
