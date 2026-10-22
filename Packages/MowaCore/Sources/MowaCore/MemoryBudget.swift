#if canImport(os)
    import os
#endif

/// The least free memory that a model load needs.
public struct MemoryBudget: Sendable, Equatable {
    /// The budget for a model load: 1.2 GB.
    public static let modelLoad = Self(minimumBytes: 1_200_000_000)

    public let minimumBytes: UInt64

    public init(minimumBytes: UInt64) {
        self.minimumBytes = minimumBytes
    }

    /// True when the free memory is equal to or more than the budget.
    public func allows(availableBytes: UInt64) -> Bool {
        availableBytes >= minimumBytes
    }
}

extension MemoryBudget {
    #if canImport(os) && !os(macOS)
        /// The free memory of the process from `os_proc_available_memory`.
        @Sendable public static func systemAvailableBytes() -> UInt64 {
            UInt64(os_proc_available_memory())
        }
    #else
        /// The platform has no per-process limit, so all memory is free.
        @Sendable public static func systemAvailableBytes() -> UInt64 {
            .max
        }
    #endif
}
