internal import Foundation
internal import WerKit

exit(
    WerMain.run(
        arguments: Array(CommandLine.arguments.dropFirst()),
        read: { try String(contentsOfFile: $0, encoding: .utf8) },
        write: { print($0, terminator: "") },
        writeError: { FileHandle.standardError.write(Data($0.utf8)) }
    )
)
