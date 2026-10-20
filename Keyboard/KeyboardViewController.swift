import MowaShared
import UIKit

final class KeyboardViewController: UIInputViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.accessibilityIdentifier = MowaShared.appGroupIdentifier
    }
}
