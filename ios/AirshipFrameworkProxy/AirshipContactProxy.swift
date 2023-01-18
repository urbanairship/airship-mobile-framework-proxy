/* Copyright Urban Airship and Contributors */

import Foundation
import AirshipKit

public class AirshipContactProxy {

    private let contactProvider: () throws -> AirshipContactProtocol
    private var contact: AirshipContactProtocol {
        get throws { try contactProvider() }
    }

    init(contactProvider: @escaping () throws -> AirshipContactProtocol) {
        self.contactProvider = contactProvider
    }

    public func setNamedUser(_ namedUser: String) throws {
        let namedUser = namedUser.trimmingCharacters(
            in: CharacterSet.whitespacesAndNewlines
        )

        if (namedUser.isEmpty) {
            try self.contact.reset()
        } else {
            try self.contact.identify(namedUser)
        }
    }

    public func getNamedUser() throws -> String {
        return try self.contact.namedUserID ?? ""
    }


    public func getContactSubscriptionLists() async throws -> [String: [String]] {
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

    public func editContactTagGroups(_ operations: Any) throws {
        let data = try JSONUtils.data(operations)
        let operations = try JSONDecoder().decode(
            [TagGroupOperation].self,
            from: data
        )
        try self.contact.editTagGroups { editor in
            operations.forEach { operation in
                operation.apply(editor: editor)
            }
        }
    }

    public func editContactAttributes(_ operations: Any) throws {
        let data = try JSONUtils.data(operations)
        let operations = try JSONDecoder().decode(
            [AttributeOperation].self,
            from: data
        )
        try self.contact.editAttributes { editor in
            operations.forEach { operation in
                operation.apply(editor: editor)
            }
        }
    }

    public func editContactSubscriptionLists(_ operations: Any) throws {
        let data = try JSONUtils.data(operations)
        let operations = try JSONDecoder().decode(
            [SubscriptionListOperation].self,
            from: data
        )
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
