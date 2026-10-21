import Synchronization
import Testing

@testable import MowaShared

final class FakeTransport: NotificationTransport {
    private let observers = Mutex<[AsyncStream<Void>.Continuation]>([])

    func post(_: DarwinNotificationName) {
        observers.withLock { $0.forEach { $0.yield() } }
    }

    func notifications(named _: DarwinNotificationName) -> AsyncStream<Void> {
        let (stream, continuation) = AsyncStream<Void>.makeStream()
        observers.withLock { $0.append(continuation) }
        return stream
    }
}

struct DarwinNotifierTests {
    @Test func receiverWakesWhenResultIsReady() async {
        let notifier = DarwinNotifier(transport: FakeTransport())
        let stream = notifier.resultReady()
        notifier.postResultReady()
        var iterator = stream.makeAsyncIterator()
        let received: Void? = await iterator.next()
        #expect(received != nil)
    }

    @Test func notificationNameIsStable() {
        #expect(DarwinNotificationName.resultReady.rawValue == "group.com.tomiwu.mowa.result-ready")
    }

    #if canImport(Darwin)
        @Test func systemTransportDeliversNotification() async {
            let notifier = DarwinNotifier(transport: SystemNotificationTransport())
            let stream = notifier.resultReady()
            notifier.postResultReady()
            var iterator = stream.makeAsyncIterator()
            let received: Void? = await iterator.next()
            #expect(received != nil)
        }
    #endif
}
