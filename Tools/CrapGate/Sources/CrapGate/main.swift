internal import CrapCore
internal import Foundation

exit(
    CrapMain.runWithFiles(
        arguments: Array(CommandLine.arguments.dropFirst()),
        write: { print($0, terminator: "") },
        writeError: { FileHandle.standardError.write(Data($0.utf8)) }
    )
)
