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
    private var pendingResolve: Task<Void, Never>?

    private let dateProvider: () -> Date

    init(dateProvider: @escaping () -> Date = { Date() }) {
        self.dateProvider = dateProvider
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

    /// Resolves the launch without a deep link. Called once the app becomes
    /// active so normal launches resolve nil without waiting.
    func onLaunchResolved() {
        launchResolved = true
        resolveWaiters()
    }

    /// Resolves the launch without a deep link after `delay`, unless a tap
    /// resolves it first or the app is backgrounded.
    ///
    /// Calling it again replaces the pending resolve.
    /// - Parameter delay: Seconds to wait before resolving.
    func resolveLaunch(after delay: TimeInterval) {
        pendingResolve?.cancel()
        pendingResolve = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            guard !Task.isCancelled else { return }
            self?.onLaunchResolved()
        }
    }

    /// Reopens the launch so the tap that brings the app back from the
    /// background counts as a launch tap. Drops any unread link, since the
    /// next return may not come from a tap.
    func onAppEnteredBackground() {
        pendingResolve?.cancel()
        pendingResolve = nil
        stash = nil
        launchResolved = false
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
