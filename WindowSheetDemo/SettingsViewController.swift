import UIKit

/// The page behind the sheet: a navigation controller with a grouped table of settings rows.
/// Turning on the "Panel" switch adds `SetupSheetView` straight to the key window,
/// the way the real-world app this was reduced from shows its bottom sheet.
final class SettingsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private struct Row {
        enum Kind { case toggle(id: String), value(String), sheetTrigger }
        let title: String
        let kind: Kind
    }

    private let sections: [(title: String, rows: [Row])] = [
        ("General", [
            Row(title: "Option A", kind: .toggle(id: "option_a_switch")),
            Row(title: "Option B", kind: .value("Manage")),
        ]),
        ("Filters", [
            Row(title: "Filter 1", kind: .toggle(id: "filter_1_switch")),
            Row(title: "Filter 2", kind: .toggle(id: "filter_2_switch")),
            Row(title: "Filter 3", kind: .toggle(id: "filter_3_switch")),
            Row(title: "Filter 4", kind: .toggle(id: "filter_4_switch")),
            Row(title: "Filter 5", kind: .toggle(id: "filter_5_switch")),
            Row(title: "Filter 6", kind: .toggle(id: "filter_6_switch")),
        ]),
        ("Extras", [
            Row(title: "Panel", kind: .sheetTrigger),
            Row(title: "Limit", kind: .value("65")),
            Row(title: "Price", kind: .value("3.20")),
            Row(title: "Payment", kind: .value("Cash")),
        ]),
    ]

    private let tableView = UITableView(frame: .zero, style: .grouped)
    private weak var triggerSwitch: UISwitch?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Settings"
        view.backgroundColor = .systemGroupedBackground
        if Options.pageModal { view.accessibilityViewIsModal = true }
        let back = UIBarButtonItem(title: "Back", style: .plain, target: nil, action: nil)
        back.accessibilityIdentifier = "back_btn"
        navigationItem.leftBarButtonItem = back

        tableView.dataSource = self
        tableView.delegate = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }

    // MARK: - Table

    func numberOfSections(in tableView: UITableView) -> Int { sections.count }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? { sections[section].title }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { sections[section].rows.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = sections[indexPath.section].rows[indexPath.row]
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.textLabel?.text = row.title
        cell.selectionStyle = .none
        switch row.kind {
        case .toggle(let id):
            let toggle = UISwitch()
            toggle.isOn = true
            toggle.accessibilityIdentifier = id
            cell.accessoryView = toggle
        case .value(let text):
            let label = UILabel()
            label.text = text
            label.textColor = .secondaryLabel
            label.sizeToFit()
            label.accessibilityIdentifier = "row_value"
            cell.accessoryView = label
        case .sheetTrigger:
            let toggle = UISwitch()
            toggle.isOn = false
            toggle.accessibilityIdentifier = "sheet_trigger_switch"
            toggle.addTarget(self, action: #selector(triggerChanged(_:)), for: .valueChanged)
            triggerSwitch = toggle
            cell.accessoryView = toggle
        }
        return cell
    }

    // MARK: - Sheet

    @objc private func triggerChanged(_ sender: UISwitch) {
        if sender.isOn { presentSheet() }
    }

    private func presentSheet() {
        let sheet = SetupSheetView()
        let finish: () -> Void = { [weak self, weak sheet] in
            sheet?.dismiss { self?.triggerSwitch?.setOn(false, animated: true) }
        }
        sheet.onClose = finish
        sheet.onConfirm = finish

        // `window.addSubview(sheet)`, then pin the sheet's edges to that window.
        let host: UIView
        if !Options.attachToView, let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) {
            host = window
        } else {
            host = view
        }
        host.addSubview(sheet)
        sheet.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            sheet.topAnchor.constraint(equalTo: host.topAnchor),
            sheet.bottomAnchor.constraint(equalTo: host.bottomAnchor),
            sheet.leadingAnchor.constraint(equalTo: host.leadingAnchor),
            sheet.trailingAnchor.constraint(equalTo: host.trailingAnchor),
        ])
    }
}
