import MapKit
import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: windowScene)

        let nav = UINavigationController(rootViewController: SettingsViewController())
        if Options.navModal { nav.view.accessibilityViewIsModal = true }

        if Options.presented || Options.presentedFull {
            let base = BaseViewController()
            window.rootViewController = base
            window.makeKeyAndVisible()
            nav.modalPresentationStyle = Options.presentedFull ? .fullScreen : .overFullScreen
            DispatchQueue.main.async { base.present(nav, animated: false) }
        } else {
            window.rootViewController = nav
            window.makeKeyAndVisible()
        }
        self.window = window
        if Options.windowOverlay { installEmptyOverlay(in: window) }
    }

    /// An empty, non-interactive, full-screen view with one full-screen child, behind the root view.
    /// The real-world app shows such a 2-node subtree next to the page in the WebDriverAgent tree.
    private func installEmptyOverlay(in window: UIWindow) {
        let outer = UIView()
        outer.isUserInteractionEnabled = false
        outer.backgroundColor = .clear
        let inner = UIView()
        inner.isUserInteractionEnabled = false
        inner.backgroundColor = .clear
        outer.addSubview(inner)
        window.insertSubview(outer, at: 0)
        for (child, parent) in [(outer, window as UIView), (inner, outer)] {
            child.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                child.topAnchor.constraint(equalTo: parent.topAnchor),
                child.bottomAnchor.constraint(equalTo: parent.bottomAnchor),
                child.leadingAnchor.constraint(equalTo: parent.leadingAnchor),
                child.trailingAnchor.constraint(equalTo: parent.trailingAnchor),
            ])
        }
    }
}

/// In the real-world app the screen under the settings page is a map screen.
final class BaseViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemTeal
        guard Options.map else { return }
        let map = MKMapView()
        map.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(map)
        NSLayoutConstraint.activate([
            map.topAnchor.constraint(equalTo: view.topAnchor),
            map.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            map.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            map.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }
}
