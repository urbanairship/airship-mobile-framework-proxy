/* Copyright Airship and Contributors */

public import ActivityKit

#if canImport(AirshipKit)
import AirshipKit
#elseif canImport(AirshipCore)
import AirshipCore
#endif

@available(iOS 16.1, *)
public actor LiveActivityManager: Sendable {

    public static let shared = LiveActivityManager()

    fileprivate struct Entry: Sendable {
        var list: @Sendable () throws -> [LiveActivityInfo]
        var start: @Sendable (LiveActivityRequest.Start) async throws -> LiveActivityInfo
        var update: @Sendable (LiveActivityRequest.Update) async throws -> Bool
        var end: @Sendable (LiveActivityRequest.End) async throws -> Bool
        var track: @Sendable (String) -> Void

        var pushToStartUpdates: @Sendable ((@escaping @Sendable () async -> Void)) -> Void
        var activityUpdates: @Sendable (String, (@escaping @Sendable (LiveActivityInfo?) async -> Void)) -> Void
    }

    private var entries: [String: Entry] = [:]
    @MainActor
    private var setupCalled: Bool = false
    private var setupTask: Task<Void, Never>? = nil

    private var activityState: [String: LiveActivityInfo] = [:]

    public actor Configurator {
        fileprivate var entries: [String: Entry] = [:]
        private var restorer: any LiveActivityRestorer

        init(restorer: any LiveActivityRestorer) {
            self.restorer = restorer
        }

        public func register<T: ActivityAttributes>(
            forType type: Activity<T>.Type,
            attributesType: String = String(describing: T.self),
            airshipNameExtractor: (@Sendable (T) -> String)?
        ) async {
            self.entries[attributesType] = Entry(
                forType: type,
                attributesType: attributesType,
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
            do {
                try track(
                    attributesType: info.attributesType,
                    activityID: info.id
                )
            } catch {
                AirshipLogger.warn("Failed to track activity: \(error)")
            }

            if activityState[info.id] == nil {
                await startWatchingActivityUpdates(
                    info.id,
                    attributesType: info.attributesType
                )
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

    private func startWatchingActivityUpdates(_ activityID: String, attributesType: String) async {
        let entry = try? self.findEntry(attributesType: attributesType)
        entry?.activityUpdates(activityID, { [weak self] info in
            await self?.updated(activityID: activityID, info: info, notifyOnChange: true)
        })
    }

    
    public func start(_ request: LiveActivityRequest.Start) async throws -> LiveActivityInfo {
        try await waitForSetup()
        let result = try await findEntry(attributesType: request.attributesType).start(request)
        if #unavailable(iOS 17.2) {
            await self.checkForActivities()
        }
        return result
    }

    public func update(_ request: LiveActivityRequest.Update) async throws -> Void {
        try await waitForSetup()
        var processed = false
        for handler in self.entries.values {
            if (try await handler.update(request)) {
                processed = true
                break
            }
        }

        guard processed else {
            throw AirshipErrors.error("Unable to update Live Activity \(request)")
        }
    }

    public func end(_ request: LiveActivityRequest.End) async throws -> Void {
        try await waitForSetup()
        var processed = false
        for handler in self.entries.values {
            if (try await handler.end(request)) {
                processed = true
                break
            }
        }

        guard processed else {
            throw AirshipErrors.error("Unable to end Live Activity \(request)")
        }
    }

    public func listAll() async throws -> [LiveActivityInfo] {
        try await waitForSetup()

        var liveActivities: [LiveActivityInfo] = []
        for handler in self.entries.values {
            liveActivities.append(contentsOf: try handler.list())
        }
        return liveActivities
    }

    public func list(_ request: LiveActivityRequest.List) async throws -> [LiveActivityInfo] {
        try await waitForSetup()
        return try self.findEntry(attributesType: request.attributesType).list()
    }

    private func waitForSetup() async throws {
        guard await self.setupCalled else {
            throw AirshipErrors.error("Setup not called")
        }
        await setupTask?.value
    }

    private func findEntry(attributesType: String) throws -> Entry {
        guard let entry = self.entries[attributesType] else {
            throw AirshipErrors.error("Missing entry for attributesType \(attributesType)")
        }
        return entry
    }

    private func track(attributesType: String, activityID: String) throws {
        guard let entry = self.entries[attributesType] else {
            throw AirshipErrors.error("Missing entry for attributesType \(attributesType)")
        }
        entry.track(activityID)
    }
}


@available(iOS 16.1, *)
extension LiveActivityManager.Entry {
    init<T: ActivityAttributes>(
        forType type: Activity<T>.Type,
        attributesType: String,
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
                    try? await Self.watchContentUpdates(
                        type,
                        activityID: id,
                        attributesType: attributesType,
                        onUpdate: callback
                    )
                }

                Task {
                    try? await Self.watchStatusUpdates(
                        type,
                        activityID: id,
                        attributesType: attributesType,
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
                try LiveActivityInfo(activity: activity, attributesType: attributesType)
            }
        }

        self.update = { request in
            try await Self.updateActivity(type, request: request)
        }

        self.start = { request in
            let activity: Activity<T> = try Self.startActivity(request: request)
            if let airshipName = airshipNameExtractor?(activity.attributes) {
                Airship.channel.trackLiveActivity(activity, name: airshipName)
            }

            return try LiveActivityInfo(activity: activity, attributesType: attributesType)
        }

        self.track = { @Sendable activityID in
            Self.track(
                type,
                activityID:activityID,
                airshipNameExtractor: airshipNameExtractor
            )
        }
    }

    private static func track<T: ActivityAttributes>(
        _ type: Activity<T>.Type,
        activityID: String,
        airshipNameExtractor: (@Sendable (T) -> String)?
    ) {
        guard
            let activity = type.activities.first(where: { $0.id == activityID })
        else {
            return
        }

        if let airshipName = airshipNameExtractor?(activity.attributes) {
            Airship.channel.trackLiveActivity(activity, name: airshipName)
        }
    }

    private static func updateActivity<T: ActivityAttributes>(
        _ type: Activity<T>.Type,
        request: LiveActivityRequest.Update
    ) async throws -> Bool {
        guard let activity = type.activities.first(where: { $0.id == request.activityID }) else {
            return false
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

        return true
    }

    private static func endActivity<T: ActivityAttributes>(
        _ type: Activity<T>.Type,
        request: LiveActivityRequest.End
    ) async throws -> Bool {
        guard let activity = type.activities.first(where: { $0.id == request.activityID }) else {
            return false
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

        return true
    }

    private static func startActivity<T: ActivityAttributes>(
        request: LiveActivityRequest.Start
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
        attributesType: String,
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

            if let info = try? LiveActivityInfo(activity: updated, attributesType: attributesType) {
                await onUpdate(info)
            }
        }
    }

    private static func watchContentUpdates<T: ActivityAttributes>(
        _ type: Activity<T>.Type,
        activityID: String,
        attributesType: String,
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

                if let info = try? LiveActivityInfo(activity: updated, attributesType: attributesType) {
                    await onUpdate(info)
                }
            }
        } else {
            for await _ in activity.contentStateUpdates {
                try Task.checkCancellation()
                guard let updated = type.activities.first(where: { $0.id == activityID }) else {
                    break
                }

                if let info = try? LiveActivityInfo(activity: updated, attributesType: attributesType) {
                    await onUpdate(info)
                }
            }
        }
    }
}
