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

    public func identify(_ namedUser: String) throws {
        let namedUser = namedUser.trimmingCharacters(
            in: CharacterSet.whitespacesAndNewlines
        )

        if (!namedUser.isEmpty) {
            try self.contact.identify(namedUser)
        } else {
            try self.contact.reset()
        }
    }

    public func reset() throws {
        try self.contact.reset()
    }

    public func notifyRemoteLogin() throws {
        try self.contact.notifyRemoteLogin()
    }

    public func getNamedUser() async throws -> String? {
        return try await self.contact.namedUserID
    }

    public func getSubscriptionLists() async throws -> [String: [String]] {
        let lists = try await self.contact.fetchSubscriptionLists()

        var converted: [String : [String]] = [:]

        lists.forEach { (key, value) in
            converted[key] = value.map { scope in
                scope.stringValue
            }
        }
        
        return converted
    }

    public func editTagGroups(json: Any) throws {
        let data = try AirshipJSONUtils.data(json)
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
        let data = try AirshipJSONUtils.data(json)
        let operations = try JSONDecoder().decode(
            [AttributeOperation].self,
            from: data
        )
        try editAttributes(operations: operations)
    }


    public func editAttributes(operations: [AttributeOperation]) throws {
        let editor = try self.contact.editAttributes()
        try operations.forEach { operation in
            try operation.apply(editor: editor)
        }
        editor.apply()
    }

    public func editSubscriptionLists(json: Any) throws {
        let data = try AirshipJSONUtils.data(json)
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

