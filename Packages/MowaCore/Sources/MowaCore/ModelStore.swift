/// Reasons why a model store cannot change the files of the model.
public enum ModelStoreError: Error, Equatable, Sendable {
    case deleteFailed
}

/// Adapter for the files of one ASR model. The engine package implements it.
public protocol ModelStore: Sendable {
    /// Size of the download in bytes. The user sees it before the download.
    var sizeInBytes: Int64 { get }

    var isInstalled: Bool { get }

    /// Downloads the model. The stream gives the fraction done (0 to 1) and fails when the
    /// download fails.
    func download() -> AsyncThrowingStream<Double, any Error>

    func delete() throws(ModelStoreError)
}

/// What the model manager shows for the model.
public enum ModelState: Equatable, Sendable {
    case notDownloaded
    case downloading(fraction: Double)
    case ready
    case failed

    /// Progress from 0 to 1, for a progress bar.
    public var fraction: Double {
        switch self {
        case .downloading(let fraction): fraction
        case .ready: 1
        case .notDownloaded, .failed: 0
        }
    }

    public var label: String {
        switch self {
        case .notDownloaded: "Not downloaded"
        case .downloading(let fraction): "Downloading \(Int(fraction * 100)) %"
        case .ready: "Ready"
        case .failed: "Failed"
        }
    }

    public var canDownload: Bool {
        self == .notDownloaded || self == .failed
    }

    public var canDelete: Bool {
        self == .ready || self == .failed
    }
}
