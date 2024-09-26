/* Copyright Airship and Contributors */

import ActivityKit

#if canImport(AirshipKit)
import AirshipKit
#elseif canImport(AirshipCore)
import AirshipCore
#endif

@available(iOS 16.1, *)
public actor LiveActivityManager: Sendable {

    public static let shared = LiveActivityManager()

    fileprivate struct Entry {
        let list: () throws -> [LiveActivityInfo]
        let create: (LiveActivityRequest.Create) async throws -> LiveActivityInfo
        let update: (LiveActivityRequest.Update) async throws -> Void
        let end: (LiveActivityRequest.End) async throws -> Void

        let pushToStartUpdates: ((@escaping @Sendable () async -> Void)) async -> Void
        let contentUpdates: (String, (@escaping @Sendable (LiveActivityInfo) async -> Void)) async -> Void
    }

    private var entries: [String: Entry] = [:]
    @MainActor
    private var setupCalled: Bool = false
    private var setupTask: Task<Void, Never>? = nil

    private var activityState: [String: LiveActivityInfo] = [:]

    public actor Configurator {
        fileprivate var entries: [String: Entry] = [:]
        private var restorer: LiveActivityRestorer

        init(restorer: LiveActivityRestorer) {
            self.restorer = restorer
        }

        public func register<T: ActivityAttributes>(
            forType type: Activity<T>.Type,
            typeReferenceID: String,
            airshipNameExtractor: (@Sendable (T) -> String)?
        ) async {
            self.entries[typeReferenceID] = Entry(
                forType: type,
                typeReferenceID: typeReferenceID,
                airshipNameExtractor: airshipNameExtractor
            )
            await restorer.restore(forType: type)
        }
    }

    @MainActor
    public func setup(setupBlock: @escaping @Sendable (Configurator) async -> Void) throws {
        guard !setupCalled else {
            throw AirshipErrors.error("Already initialized")
        }

        self.setupCalled = true

        Task {
            try await beginSetup(setupBlock: setupBlock)
        }
    }

    private func beginSetup(setupBlock: @escaping @Sendable (Configurator) async -> Void) async throws {
        self.setupTask = Task {
            await withUnsafeContinuation { continuation in
                Task {
                    await Airship.onReady {
                        Airship.channel.restoreLiveActivityTracking { restorer in
                            let configurator = Configurator(restorer: restorer)
                            await setupBlock(configurator)
                            await self.finishSetup(configurator: configurator)
                            continuation.resume()
                        }
                    }
                }
            }
        }
    }

    private func finishSetup(configurator: Configurator) async {
        self.entries = await configurator.entries

        self.entries.values.forEach { entry in
            Task { [weak self] in
                await entry.pushToStartUpdates { [weak self] in
                    await self?.checkForActivities()
                }
            }
        }
    }

    private func checkForActivities() async {
        var update = false
        let all = self.entries.values.compactMap { try? $0.list() }.joined()
        for info in all {
            if activityState[info.id] == nil {
                await updated(info: info, notifyOnChange: false)
                update = true
            }
        }

        if (update) {
            await notify()
        }
    }

    private func updated(info: LiveActivityInfo, notifyOnChange: Bool) async {
        guard activityState[info.id] != info else {
            return
        }

        activityState[info.id] = info

        if (notifyOnChange) {
            await notify()
        }
    }

    private func notify() async {
        let activities = self.activityState.values.sorted { f, s in
            return f.id.compare(s.id) == .orderedAscending
        }

        await AirshipProxyEventEmitter.shared.addEvent(LiveActivitiesUpdatedEvent(activities))
    }

    private func startWatching(_ info: LiveActivityInfo) {
        Task { [weak self] in
            let entry = try await self?.findEntry(typeReferenceID: info.typeReferenceID)
            await entry?.contentUpdates(info.id, { [weak self] info in
                await self?.updated(info: info, notifyOnChange: true)
            })
        }
    }

    public func create(_ request: LiveActivityRequest.Create) async throws -> LiveActivityInfo {
        let result = try await findEntry(typeReferenceID: request.typeReferenceID).create(request)
        if #available(iOS 17.2, *) {} else {
            await self.checkForActivities()
        }
        return result
    }

    public func update(_ request: LiveActivityRequest.Update) async throws -> Void {
        try await findEntry(typeReferenceID: request.typeReferenceID).update(request)
    }

    public func end(_ request: LiveActivityRequest.End) async throws -> Void {
        try await findEntry(typeReferenceID: request.typeReferenceID).end(request)
    }

    public func list(_ request: LiveActivityRequest.List) async throws -> [LiveActivityInfo] {
        return try await findEntry(typeReferenceID: request.typeReferenceID).list()
    }

    private func findEntry(typeReferenceID: String) async throws -> Entry {
        guard await self.setupCalled else {
            throw AirshipErrors.error("Setup not called")
        }
        await setupTask?.value
        guard let entry = self.entries[typeReferenceID] else {
            throw AirshipErrors.error("Missing entry for typeReferenceID \(typeReferenceID)")
        }
        return entry
    }
}


@available(iOS 16.1, *)
extension LiveActivityManager.Entry {
    init<T: ActivityAttributes>(
        forType type: Activity<T>.Type,
        typeReferenceID: String,
        airshipNameExtractor: (@Sendable (T) -> String)?
    ) {

        self.pushToStartUpdates = { callback in
            if #available(iOS 17.2, *) {
                for await _ in type.pushToStartTokenUpdates {
                    await callback()
                }
            }
        }

        self.contentUpdates = { id, callback in
            guard let activity = type.activities.first(where: { $0.id == id }) else {
               return
            }

            if #available(iOS 16.2, *) {
                for await _ in activity.contentUpdates {
                    guard let updated = type.activities.first(where: { $0.id == id }) else {
                        return
                    }

                    if let info = try? LiveActivityInfo(activity: updated, typeReferenceID: typeReferenceID) {
                        await callback(info)
                    }
                }
            } else {
                for await _ in activity.contentStateUpdates {
                    guard let updated = type.activities.first(where: { $0.id == id }) else {
                        return
                    }

                    if let info = try? LiveActivityInfo(activity: updated, typeReferenceID: typeReferenceID) {
                        await callback(info)
                    }
                }
            }
        }

        self.end = { request in
            guard let activity = type.activities.first(where: { $0.id == request.activityID }) else {
                throw AirshipErrors.error("No activity found with activityID \(request.activityID) typeReferenceID \(typeReferenceID)")
            }
            try await Self.endActivity(activity, request: request)
        }

        self.list = {
            return try type.activities.map { activity in
                try LiveActivityInfo(activity: activity, typeReferenceID: typeReferenceID)
            }
        }

        self.update = { request in
            guard let activity = type.activities.first(where: { $0.id == request.activityID }) else {
                throw AirshipErrors.error("No activity found with activityID \(request.activityID) typeReferenceID \(typeReferenceID)")
            }

            try await Self.updateActivity(activity, request: request)
        }

        self.create = { request in
            let activity: Activity<T> = try Self.createActivity(request: request)
            if let airshipName = airshipNameExtractor?(activity.attributes) {
                Airship.channel.trackLiveActivity(activity, name: airshipName)
            }

            return try LiveActivityInfo(activity: activity, typeReferenceID: typeReferenceID)
        }
    }

    private static func updateActivity<T: ActivityAttributes>(
        _ activity: Activity<T>,
        request: LiveActivityRequest.Update
    ) async throws {
        let decodedContentState: T.ContentState = try request.content.state.decode()
        if #available(iOS 16.2, *) {
            let content = ActivityContent(
                state: decodedContentState,
                staleDate: request.content.staleDate,
                relevanceScore: request.content.relevanceScore
            )

            if #available(iOS 17.2, *) {
                await activity.update(content, timestamp: request.timestamp ?? Date())
            } else {
                await activity.update(content)
            }
        } else {
            await activity.update(using: decodedContentState)
        }
    }

    private static func endActivity<T: ActivityAttributes>(
        _ activity: Activity<T>,
        request: LiveActivityRequest.End
    ) async throws {

        let dismissalPolicy: ActivityUIDismissalPolicy = switch(request.dismissalPolicy ??  .default) {
        case .after(let date): .after(date)
        case .default: .default
        case .immediate: .immediate
        }

        if #available(iOS 16.2, *) {
            let activityContent: ActivityContent<T.ContentState>? = if let content = request.content {
                ActivityContent(
                    state: try content.state.decode(),
                    staleDate: content.staleDate,
                    relevanceScore: content.relevanceScore
                )
            } else {
                nil
            }

            if #available(iOS 17.2, *) {
                await activity.end(activityContent, dismissalPolicy: dismissalPolicy, timestamp: request.timestamp ?? Date())
            } else {
                await activity.end(activityContent, dismissalPolicy: dismissalPolicy)
            }
        } else {
            await activity.end(
                using: try request.content?.state.decode(),
                dismissalPolicy: dismissalPolicy
            )
        }
    }

    private static func createActivity<T: ActivityAttributes>(
        request: LiveActivityRequest.Create
    ) throws -> Activity<T> {
        let decodedAttributes: T = try request.attributes.decode()
        let decodedContentState: T.ContentState = try request.content.state.decode()

        if #available(iOS 16.2, *) {
            return try Activity.request(
                attributes: decodedAttributes,
                content: ActivityContent(
                    state: decodedContentState,
                    staleDate: request.content.staleDate,
                    relevanceScore: request.content.relevanceScore
                ),
                pushType: .token
            )
        } else {
            return try Activity.request(
                attributes: decodedAttributes,
                contentState: decodedContentState,
                pushType: .token
            )
        }
    }
}
