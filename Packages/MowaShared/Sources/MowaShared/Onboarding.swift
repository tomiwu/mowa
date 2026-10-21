/// State of the microphone permission.
public enum MicrophonePermission: Equatable, Sendable {
    case undetermined
    case granted
    case denied
}

/// A step of the first-run flow.
public enum OnboardingStep: CaseIterable, Equatable, Sendable {
    case keyboard
    case fullAccess
    case microphone

    public var title: String {
        switch self {
        case .keyboard: "Add the keyboard"
        case .fullAccess: "Turn on Full Access"
        case .microphone: "Allow the microphone"
        }
    }

    /// Simple words that tell the user what to do and why.
    public var explanation: String {
        switch self {
        case .keyboard:
            "Open Settings, General, Keyboard, Keyboards. Add Mowa."
        case .fullAccess:
            "Full Access lets the keyboard share text with this app. "
                + "The keyboard uses it only for the App Group and for messages to the app. "
                + "It does not send your text or audio over the network."
        case .microphone:
            "A keyboard cannot ask for the microphone. "
                + "This app asks, and it records only while a session is active."
        }
    }
}

/// What the app detects about the setup. It decides which step the user sees.
public struct OnboardingState: Equatable, Sendable {
    public var keyboardAdded: Bool
    public var fullAccess: Bool
    public var microphone: MicrophonePermission

    public init(keyboardAdded: Bool, fullAccess: Bool, microphone: MicrophonePermission) {
        self.keyboardAdded = keyboardAdded
        self.fullAccess = fullAccess
        self.microphone = microphone
    }

    public func isDone(_ step: OnboardingStep) -> Bool {
        switch step {
        case .keyboard: keyboardAdded
        case .fullAccess: keyboardAdded && fullAccess
        case .microphone: microphone == .granted
        }
    }

    /// The first step that is not done, or `nil` when the flow is complete.
    public var currentStep: OnboardingStep? {
        OnboardingStep.allCases.first { !isDone($0) }
    }

    public var isComplete: Bool {
        currentStep == nil
    }
}

extension OnboardingState {
    /// Builds the state from the keyboard report and the microphone permission.
    public static func detect(
        report: KeyboardReport?,
        microphone: MicrophonePermission
    ) -> OnboardingState {
        OnboardingState(
            keyboardAdded: report != nil,
            fullAccess: report?.hasFullAccess == true,
            microphone: microphone
        )
    }
}
