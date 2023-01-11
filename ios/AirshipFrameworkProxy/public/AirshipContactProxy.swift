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
        try ensureAirshipReady()

        let namedUser = namedUser.trimmingCharacters(
            in: CharacterSet.whitespacesAndNewlines
        )

        if (namedUser.isEmpty) {
            Airship.contact.reset()
        } else {
            Airship.contact.identify(namedUser)
        }
    }

    public func getNamedUser() throws -> String {
        try ensureAirshipReady()
        return Airship.contact.namedUserID ?? ""
    }


    public func getContactSubscriptionLists() async throws -> [String: [String]] {
        try ensureAirshipReady()
        return try await withCheckedThrowingContinuation { continuation in
            Airship.contact.fetchSubscriptionLists { lists, error in
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
        try ensureAirshipReady()
        let data = try JSONUtils.data(operations)
        let operations = try JSONDecoder().decode(
            [TagGroupOperation].self,
            from: data
        )
        Airship.contact.editTagGroups { editor in
            operations.forEach { operation in
                operation.apply(editor: editor)
            }
        }
    }

    public func editContactAttributes(_ operations: Any) throws {
        try ensureAirshipReady()
        let data = try JSONUtils.data(operations)
        let operations = try JSONDecoder().decode(
            [AttributeOperation].self,
            from: data
        )
        Airship.contact.editAttributes { editor in
            operations.forEach { operation in
                operation.apply(editor: editor)
            }
        }
    }

    public func editContactSubscriptionLists(_ operations: Any) throws {
        try ensureAirshipReady()
        let data = try JSONUtils.data(operations)
        let operations = try JSONDecoder().decode(
            [SubscriptionListOperation].self,
            from: data
        )
        Airship.contact.editSubscriptionLists { editor in
            operations.forEach { operation in
                operation.apply(editor: editor)
            }
        }
    }
}

protocol AirshipContactProtocol: AnyObject {

}
