/* Copyright Airship and Contributors */

import Foundation

#if canImport(AirshipKit)
import AirshipKit
#elseif canImport(AirshipCore)
import AirshipCore
#endif

/// Tracks the deep link that launched the app from a notification tap.
///
/// The stash is consume-once and expires after `maxStashAge` so a JS reload
/// or a stale foreground tap can't replay an old launch link.
@MainActor
final class LaunchDeepLinkTracker {

    static let shared = LaunchDeepLinkTracker()

    private static let deepLinkActionKeys = ["^d", "deep_link_action"]
    private static let maxStashAge: TimeInterval = 10.0

    private var stash: (deepLink: String, date: Date)?
    private var launchResolved = false
    private var waiters: [CheckedContinuation<String?, Never>] = []
    private(set) var pendingResolve: Task<Void, Never>?

    private let dateProvider: () -> Date
    private let sleep: @Sendable (TimeInterval) async -> Void

    init(
        dateProvider: @escaping () -> Date = { Date() },
        sleep: @escaping @Sendable (TimeInterval) async -> Void = { seconds in
            try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
        }
    ) {
        self.dateProvider = dateProvider
        self.sleep = sleep
    }

    /// Called from the notification response handler for a response that
    /// opens the app. The first one resolves the launch, stashing the
    /// payload's deep link for a default-action tap; responses after the
    /// launch resolved were made while the app was in use and are ignored.
    func onNotificationResponse(
        userInfo: [AnyHashable: Any],
        isDefaultAction: Bool
    ) {
        guard !launchResolved else { return }
        if isDefaultAction {
            let deepLink = Self.deepLinkActionKeys
                .compactMap { userInfo[$0] as? String }
                .first
            if let deepLink {
                stash = (deepLink, dateProvider())
            }
        }
        launchResolved = true
        resolveWaiters()
    }

    /// Resolves the launch without a deep link.
    func onLaunchResolved() {
        launchResolved = true
        resolveWaiters()
    }

    /// Resolves the launch, or waits up to `maxStashAge` for a tap the SDK
    /// forwards only after running the notification's actions.
    /// - Parameter tapPending: Whether a recorded tap is still on its way.
    func onAppBecameActive(tapPending: Bool) {
        guard !launchResolved else { return }
        guard tapPending else {
            onLaunchResolved()
            return
        }
        pendingResolve?.cancel()
        let sleep = self.sleep
        pendingResolve = Task { [weak self] in
            await sleep(Self.maxStashAge)
            guard !Task.isCancelled else { return }
            self?.onLaunchResolved()
        }
    }

    /// Drops any unread launch link.
    func onAppEnteredBackground() {
        stash = nil
    }

    /// Returns the deep link that launched the app, or nil. Consumes the value.
    func takeLaunchDeepLink() async -> String? {
        if let deepLink = takeFreshStash() {
            return deepLink
        }
        if launchResolved {
            return nil
        }
        return await withCheckedContinuation { waiters.append($0) }
    }

    private func takeFreshStash() -> String? {
        guard let stash else { return nil }
        self.stash = nil
        guard dateProvider().timeIntervalSince(stash.date) <= Self.maxStashAge else {
            return nil
        }
        return stash.deepLink
    }

    private func resolveWaiters() {
        guard !waiters.isEmpty else { return }
        let result = takeFreshStash()
        let pending = waiters
        waiters = []
        pending.forEach { $0.resume(returning: result) }
    }
}
