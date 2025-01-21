/* Copyright Airship and Contributors */

import Foundation
@preconcurrency import Combine

#if canImport(AirshipKit)
import AirshipKit
#elseif canImport(AirshipCore)
import AirshipCore
#endif


public actor EmbeddedEventEmitter {
    static let shared: EmbeddedEventEmitter = EmbeddedEventEmitter(
        proxyEventEmitter: AirshipProxyEventEmitter.shared
    )

    private var lastEvent: (any AirshipProxyEvent)?
    private var task: Task<Void, Never>?


    private let proxyEventEmitter: AirshipProxyEventEmitter
    init(proxyEventEmitter: AirshipProxyEventEmitter) {
        self.proxyEventEmitter = proxyEventEmitter
    }

    func start() {
        task?.cancel()
        task = Task {
            for await pending in await AirshipEmbeddedObserver().updates {
                await processEvent(EmbeddedInfoUpdatedEvent(pending: pending))
            }
        }
    }

    func stop() {
        task?.cancel()
    }

    private func processEvent(_ event: EmbeddedInfoUpdatedEvent) async {
        self.lastEvent = event

        await AirshipProxyEventEmitter.shared.addEvent(
            event,
            replacePending: true
        )
    }

    func resendLastEvent() async {
        if let lastEvent {
            await AirshipProxyEventEmitter.shared.addEvent(
                lastEvent,
                replacePending: true
            )
        }
    }
}


fileprivate extension AirshipEmbeddedObserver {
    var updates: AsyncStream<[AirshipEmbeddedInfo]> {
        AsyncStream<[AirshipEmbeddedInfo]> { continuation in
            let cancellation = self.$embeddedInfos.sink { embeddedInfos in
                continuation.yield(embeddedInfos)
            }
            
            continuation.onTermination = { _ in
                cancellation.cancel()
            }
        }
    }
}
