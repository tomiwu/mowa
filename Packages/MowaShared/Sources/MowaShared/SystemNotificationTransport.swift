#if canImport(Darwin)
    import CoreFoundation

    /// Transport that uses the system Darwin notify center.
    public struct SystemNotificationTransport: NotificationTransport {
        public init() {}

        public func post(_ name: DarwinNotificationName) {
            CFNotificationCenterPostNotification(
                CFNotificationCenterGetDarwinNotifyCenter(),
                CFNotificationName(name.rawValue as CFString),
                nil,
                nil,
                true
            )
        }

        public func notifications(named name: DarwinNotificationName) -> AsyncStream<Void> {
            AsyncStream { continuation in
                let box = ContinuationBox(continuation)
                CFNotificationCenterAddObserver(
                    CFNotificationCenterGetDarwinNotifyCenter(),
                    box.pointer,
                    { _, observer, _, _, _ in
                        guard let observer else { return }
                        Unmanaged<ContinuationBox>.fromOpaque(observer)
                            .takeUnretainedValue().continuation.yield()
                    },
                    name.rawValue as CFString,
                    nil,
                    .deliverImmediately
                )
                continuation.onTermination = { _ in
                    CFNotificationCenterRemoveObserver(
                        CFNotificationCenterGetDarwinNotifyCenter(),
                        box.pointer,
                        CFNotificationName(name.rawValue as CFString),
                        nil
                    )
                }
            }
        }
    }

    private final class ContinuationBox: Sendable {
        let continuation: AsyncStream<Void>.Continuation

        init(_ continuation: AsyncStream<Void>.Continuation) {
            self.continuation = continuation
        }

        var pointer: UnsafeRawPointer {
            UnsafeRawPointer(Unmanaged.passUnretained(self).toOpaque())
        }
    }
#endif
