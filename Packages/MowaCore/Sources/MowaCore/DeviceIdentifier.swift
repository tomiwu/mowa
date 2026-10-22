import Foundation

/// The hardware identifier of the device, for example `iPhone12,1`.
public enum DeviceIdentifier {
    /// The identifier of this device. The simulator reports the identifier of the modeled device.
    public static var current: String {
        resolve(
            simulatorModel: ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"],
            machine: machine()
        )
    }

    /// The simulator model when it exists, and the machine name otherwise.
    static func resolve(simulatorModel: String?, machine: String) -> String {
        simulatorModel ?? machine
    }

    private static func machine() -> String {
        var info = utsname()
        uname(&info)
        let size = MemoryLayout.size(ofValue: info.machine)
        return withUnsafePointer(to: &info.machine) { pointer in
            pointer.withMemoryRebound(to: CChar.self, capacity: size) { String(cString: $0) }
        }
    }
}
