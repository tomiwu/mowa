/// Text for the size of a download.
public enum ByteSizeText {
    private static let megabyte: Int64 = 1_000_000

    /// Gives the size in megabytes, for example "595 MB". One megabyte is 1,000,000 bytes.
    public static func text(for bytes: Int64) -> String {
        "\((bytes + megabyte / 2) / megabyte) MB"
    }
}
