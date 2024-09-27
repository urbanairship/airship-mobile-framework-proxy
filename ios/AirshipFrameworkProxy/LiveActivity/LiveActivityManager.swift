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

        let pushToStartUpdates: ((@escaping @Sendable () async -> Void)) -> Void
        let activityUpdates: (String, (@escaping @Sendable (LiveActivityInfo?) async -> Void)) -> Void
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
            entry.pushToStartUpdates { [weak self] in
                await self?.checkForActivities()
            }
        }
    }

    private func checkForActivities() async {
        var update = false
        let all = self.entries.values.compactMap { try? $0.list() }.joined()
        for info in all {
            if activityState[info.id] == nil {
                await startWatchingActivityUpdates(info.id, typeReferenceID: info.typeReferenceID)
                await updated(activityID: info.id, info: info, notifyOnChange: false)
                update = true
            }
        }

        if (update) {
            await notify()
        }
    }

    private func updated(activityID: String, info: LiveActivityInfo?, notifyOnChange: Bool) async {
        guard activityState[activityID] != info else {
            return
        }

        activityState[activityID] = info

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

    private func startWatchingActivityUpdates(_ activityID: String, typeReferenceID: String) async {
        let entry = try? await self.findEntry(typeReferenceID: typeReferenceID)
        entry?.activityUpdates(activityID, { [weak self] info in
            await self?.updated(activityID: activityID, info: info, notifyOnChange: true)
        })
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
            Task {
                if #available(iOS 17.2, *) {
                    for await _ in type.pushToStartTokenUpdates {
                        await callback()
                    }
                }
            }
        }

        self.activityUpdates = { id, callback in
            Task {
                let contentTask = Task {
                    try? await Self.watchContentUpates(
                        type,
                        activityID: id,
                        typeReferenceID: typeReferenceID,
                        onUpdate: callback
                    )
                }

                Task {
                    try? await Self.watchStatusUpdates(
                        type,
                        activityID: id,
                        typeReferenceID: typeReferenceID,
                        onUpdate: callback
                    )
                    contentTask.cancel()
                }
            }
        }

        self.end = { request in
            try await Self.endActivity(type, request: request)
        }

        self.list = {
            return try type.activities.map { activity in
                try LiveActivityInfo(activity: activity, typeReferenceID: typeReferenceID)
            }
        }

        self.update = { request in
            try await Self.updateActivity(type, request: request)
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
        _ type: Activity<T>.Type,
        request: LiveActivityRequest.Update
    ) async throws {
        guard let activity = type.activities.first(where: { $0.id == request.activityID }) else {
            throw AirshipErrors.error("No activity found with activityID \(request.activityID)")
        }

        let decodedContentState: T.ContentState = try request.content.state.decode()
        if #available(iOS 16.2, *) {
            let content = ActivityContent(
                state: decodedContentState,
                staleDate: request.content.staleDate,
                relevanceScore: request.content.relevanceScore
            )

            await activity.update(content)
        } else {
            await activity.update(using: decodedContentState)
        }
    }

    private static func endActivity<T: ActivityAttributes>(
        _ type: Activity<T>.Type,
        request: LiveActivityRequest.End
    ) async throws {
        guard let activity = type.activities.first(where: { $0.id == request.activityID }) else {
            throw AirshipErrors.error("No activity found with activityID \(request.activityID)")
        }

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

            await activity.end(activityContent, dismissalPolicy: dismissalPolicy)
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

    private static func watchStatusUpdates<T: ActivityAttributes>(
        _ type: Activity<T>.Type,
        activityID: String,
        typeReferenceID: String,
        onUpdate: @escaping @Sendable (LiveActivityInfo?) async -> Void
    ) async throws {
        guard let activity = type.activities.first(where: { $0.id == activityID }) else {
            return
        }

        for await _ in activity.activityStateUpdates {
            guard let updated = type.activities.first(where: { $0.id == activityID }) else {
                await onUpdate(nil)
                return
            }

            if let info = try? LiveActivityInfo(activity: updated, typeReferenceID: typeReferenceID) {
                await onUpdate(info)
            }
        }
    }

    private static func watchContentUpates<T: ActivityAttributes>(
        _ type: Activity<T>.Type,
        activityID: String,
        typeReferenceID: String,
        onUpdate: @escaping @Sendable (LiveActivityInfo?) async -> Void
    ) async throws {
        guard let activity = type.activities.first(where: { $0.id == activityID }) else {
           return
        }

        if #available(iOS 16.2, *) {
            for await _ in activity.contentUpdates {
                try Task.checkCancellation()
                guard let updated = type.activities.first(where: { $0.id == activityID }) else {
                    break
                }

                if let info = try? LiveActivityInfo(activity: updated, typeReferenceID: typeReferenceID) {
                    await onUpdate(info)
                }
            }
        } else {
            for await _ in activity.contentStateUpdates {
                try Task.checkCancellation()
                guard let updated = type.activities.first(where: { $0.id == activityID }) else {
                    break
                }

                if let info = try? LiveActivityInfo(activity: updated, typeReferenceID: typeReferenceID) {
                    await onUpdate(info)
                }
            }
        }
    }
}
