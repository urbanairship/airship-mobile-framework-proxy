/* Copyright Urban Airship and Contributors */

import Foundation

#if canImport(AirshipKit)
import AirshipKit
#elseif canImport(AirshipCore)
import AirshipCore
#endif

public final class AirshipContactProxy: Sendable {

    private let contactProvider: @Sendable () throws -> any AirshipContactProtocol
    private var contact: any AirshipContactProtocol {
        get throws { try contactProvider() }
    }

    init(contactProvider: @Sendable @escaping () throws -> any AirshipContactProtocol) {
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

    public var namedUserID: String? {
        get async throws {
            return try await self.contact.namedUserID
        }
    }

    public func getSubscriptionLists() async throws -> [String: [String]] {
        let lists = try await self.contact.fetchSubscriptionLists()

        var converted: [String : [String]] = [:]

        lists.forEach { (key, value) in
            converted[key] = value.map { scope in
                scope.rawValue
            }
        }
        
        return converted
    }

    public func editTagGroups(operations: [TagGroupOperation]) throws {
        try self.contact.editTagGroups { editor in
            operations.forEach { operation in
                operation.apply(editor: editor)
            }
        }
    }

    public func editAttributes(operations: [AttributeOperation]) throws {
        let editor = try self.contact.editAttributes()
        try operations.forEach { operation in
            try operation.apply(editor: editor)
        }
        editor.apply()
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

