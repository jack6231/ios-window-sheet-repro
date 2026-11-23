import UIKit

/// Structure switches, read from the `DEMO_OPTS` environment variable (comma separated),
/// so one binary can be bisected without rebuilding:
///
///     xcrun devicectl device process launch --device <id> --terminate-existing \
///         -e '{"DEMO_OPTS":"pageModal,map"}' com.example.WindowSheetDemo
///
/// The value is stored in `UserDefaults` when it is given, so the app keeps it when a test driver
/// relaunches the process without the environment. Launch with `{"DEMO_OPTS":""}` to reset.
///
/// With no option the demo matches the real-world app's sheet: a full-screen view added to the
/// key window, whose nested container has `accessibilityViewIsModal = true`.
enum Options {
    private static let tokens: Set<String> = {
        let key = "DEMO_OPTS"
        let defaults = UserDefaults.standard
        if let given = ProcessInfo.processInfo.environment[key] {
            defaults.set(given, forKey: key)
        }
        let raw = defaults.string(forKey: key) ?? ""
        return Set(raw.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) })
    }()

    static func has(_ token: String) -> Bool { tokens.contains(token) }

    // Sheet
    /// `containerView.accessibilityViewIsModal` (on by default; `noContainerModal` turns it off).
    static var containerModal: Bool { !has("noContainerModal") }
    /// `accessibilityViewIsModal` on the sheet's root view as well.
    static var sheetRootModal: Bool { has("sheetRootModal") }
    /// The sheet root swallows touches for a short time after it appears (`noHitGuard` turns it off).
    static var hitGuard: Bool { !has("noHitGuard") }
    /// Add the sheet to the root view controller's view instead of the key window.
    static var attachToView: Bool { has("attachView") }

    // Page behind the sheet
    /// `accessibilityViewIsModal` on the page's view.
    static var pageModal: Bool { has("pageModal") }
    /// `accessibilityViewIsModal` on the navigation controller's view.
    static var navModal: Bool { has("navModal") }
    /// Present the navigation controller over a base screen (`.overFullScreen`) instead of making it the window root.
    static var presented: Bool { has("presented") }
    /// Same, with `.fullScreen`.
    static var presentedFull: Bool { has("presentedFull") }
    /// The base screen holds a full-screen map view.
    static var map: Bool { has("map") }

    // Window
    /// Insert an empty full-screen view (with one full-screen child) at index 0 of the window (`noOverlay` turns it off).
    static var windowOverlay: Bool { !has("noOverlay") }
}
