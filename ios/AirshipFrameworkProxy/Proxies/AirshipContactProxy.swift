/* Copyright Urban Airship and Contributors */

import Foundation

#if canImport(AirshipKit)
import AirshipKit
#elseif canImport(AirshipCore)
import AirshipCore
#endif

public final class AirshipContactProxy: Sendable {

    private let contactProvider: @Sendable () throws -> any AirshipContact
    private var contact: any AirshipContact {
        get throws { try contactProvider() }
    }

    init(contactProvider: @Sendable @escaping () throws -> any AirshipContact) {
        self.contactProvider = contactProvider
    }

    public func identify(_ namedUser: String) throws {
        AirshipLogger.trace("identify called, namedUser=\(namedUser)")
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
        AirshipLogger.trace("reset called")
        try self.contact.reset()
    }

    public func notifyRemoteLogin() throws {
        AirshipLogger.trace("notifyRemoteLogin called")
        try self.contact.notifyRemoteLogin()
    }

    public var namedUserID: String? {
        get async throws {
            return try await self.contact.namedUserID
        }
    }

    public func getSubscriptionLists() async throws -> [String: [String]] {
        AirshipLogger.trace("getSubscriptionLists called")
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
        AirshipLogger.trace("editTagGroups called, operations=\(operations.count)")
        try self.contact.editTagGroups { editor in
            operations.forEach { operation in
                operation.apply(editor: editor)
            }
        }
    }

    public func editAttributes(operations: [AttributeOperation]) throws {
        AirshipLogger.trace("editAttributes called, operations=\(operations.count)")
        let editor = try self.contact.editAttributes()
        try operations.forEach { operation in
            try operation.apply(editor: editor)
        }
        editor.apply()
    }

    public func editSubscriptionLists(
        operations: [ScopedSubscriptionListOperation]
    ) throws {
        AirshipLogger.trace("editSubscriptionLists called, operations=\(operations.count)")
        try self.contact.editSubscriptionLists { editor in
            operations.forEach { operation in
                operation.apply(editor: editor)
            }
        }
    }
}

