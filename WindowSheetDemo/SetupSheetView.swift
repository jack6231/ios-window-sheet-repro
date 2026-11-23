import UIKit

/// A bottom sheet implemented as a plain full-screen `UIView` that is added to the key window.
///
/// Structure (mirrors the real-world view):
///
///     SetupSheetView            full-screen, added with window.addSubview
///     ├─ dimmingView            full-screen, taps close the sheet
///     └─ containerView          rounded top corners, accessibilityViewIsModal = true
///        ├─ headerView          titleLabel + closeButton
///        ├─ scrollView          switch row, two option groups, four circles
///        └─ confirmContainer    separator + confirm button
final class SetupSheetView: UIView {

    var onClose: (() -> Void)?
    var onConfirm: (() -> Void)?

    private let dimmingView = UIView()
    private let containerView = UIView()
    private let headerView = UIView()
    private let titleLabel = UILabel()
    private let closeButton = UIButton(type: .custom)
    private let scrollView = UIScrollView()
    private let scrollContentView = UIView()
    private let contentStack = UIStackView()
    private let confirmContainer = UIView()
    private let confirmButton = UIButton(type: .system)

    private var hasAnimatedIn = false
    private var acceptsTouchesAfter: CFTimeInterval = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        setupDimming()
        setupContainer()
        setupHeader()
        setupConfirm()
        setupScroll()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Touch guard (the real-world view has the same override)

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard Options.hitGuard else { return super.hitTest(point, with: event) }
        let now = CACurrentMediaTime()
        guard now >= acceptsTouchesAfter else {
            if event?.type == .touches { acceptsTouchesAfter = max(acceptsTouchesAfter, now + 0.6) }
            return self.point(inside: point, with: event) ? self : nil
        }
        return super.hitTest(point, with: event)
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        guard window != nil, !hasAnimatedIn else { return }
        hasAnimatedIn = true
        acceptsTouchesAfter = CACurrentMediaTime() + 0.28 + 0.5
        layoutIfNeeded()
        containerView.transform = CGAffineTransform(translationX: 0, y: 60)
        containerView.alpha = 0
        UIView.animate(withDuration: 0.28, delay: 0, usingSpringWithDamping: 0.9,
                       initialSpringVelocity: 0.5, options: [.curveEaseOut]) {
            self.dimmingView.alpha = 1
            self.containerView.transform = .identity
            self.containerView.alpha = 1
        }
    }

    func dismiss(completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.22, delay: 0, options: [.curveEaseInOut], animations: {
            self.dimmingView.alpha = 0
            self.containerView.transform = CGAffineTransform(translationX: 0, y: 40)
            self.containerView.alpha = 0
        }, completion: { _ in
            self.removeFromSuperview()
            completion?()
        })
    }

    @objc private func closeTapped() { onClose?() }
    @objc private func confirmTapped() { onConfirm?() }

    // MARK: - Setup

    private func setupDimming() {
        addSubview(dimmingView)
        dimmingView.alpha = 0
        dimmingView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        pin(dimmingView, to: self)
        dimmingView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(closeTapped)))
    }

    private func setupContainer() {
        addSubview(containerView)
        containerView.backgroundColor = .systemBackground
        containerView.layer.cornerRadius = 20
        containerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        containerView.clipsToBounds = true
        containerView.accessibilityIdentifier = "sheet_container"
        containerView.accessibilityViewIsModal = Options.containerModal
        accessibilityViewIsModal = Options.sheetRootModal

        containerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            containerView.topAnchor.constraint(greaterThanOrEqualTo: safeAreaLayoutGuide.topAnchor, constant: 16),
        ])
    }

    private func setupHeader() {
        containerView.addSubview(headerView)
        headerView.addSubview(titleLabel)
        headerView.addSubview(closeButton)
        [headerView, titleLabel, closeButton].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        titleLabel.text = "Set Up Panel"
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.accessibilityIdentifier = "sheet_title_label"

        closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        closeButton.tintColor = .secondaryLabel
        closeButton.accessibilityIdentifier = "sheet_close"
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: containerView.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            closeButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            closeButton.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 16),
            closeButton.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 32),
            closeButton.heightAnchor.constraint(equalToConstant: 32),
            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            titleLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: closeButton.leadingAnchor, constant: -4),
            titleLabel.bottomAnchor.constraint(lessThanOrEqualTo: headerView.bottomAnchor, constant: -16),
        ])
    }

    private func setupConfirm() {
        containerView.addSubview(confirmContainer)
        let separator = UIView()
        separator.backgroundColor = .separator
        confirmContainer.addSubview(separator)
        confirmContainer.addSubview(confirmButton)
        [confirmContainer, separator, confirmButton].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        confirmButton.setTitle("Confirm", for: .normal)
        confirmButton.setTitleColor(.white, for: .normal)
        confirmButton.backgroundColor = .systemBlue
        confirmButton.layer.cornerRadius = 8
        confirmButton.accessibilityIdentifier = "sheet_confirm_btn"
        confirmButton.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)

        NSLayoutConstraint.activate([
            confirmContainer.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            confirmContainer.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            confirmContainer.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            separator.topAnchor.constraint(equalTo: confirmContainer.topAnchor),
            separator.leadingAnchor.constraint(equalTo: confirmContainer.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: confirmContainer.trailingAnchor),
            separator.heightAnchor.constraint(equalToConstant: 1),
            confirmButton.topAnchor.constraint(equalTo: separator.bottomAnchor, constant: 12),
            confirmButton.leadingAnchor.constraint(equalTo: confirmContainer.leadingAnchor, constant: 16),
            confirmButton.trailingAnchor.constraint(equalTo: confirmContainer.trailingAnchor, constant: -16),
            confirmButton.heightAnchor.constraint(equalToConstant: 44),
            confirmButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -12),
        ])
    }

    private func setupScroll() {
        containerView.addSubview(scrollView)
        scrollView.addSubview(scrollContentView)
        scrollContentView.addSubview(contentStack)
        [scrollView, scrollContentView, contentStack].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        scrollView.alwaysBounceVertical = false
        scrollView.showsVerticalScrollIndicator = true
        scrollView.contentInsetAdjustmentBehavior = .never
        contentStack.axis = .vertical

        // The scroll view is as tall as its content (low priority) until the sheet hits the top inset.
        let fit = scrollView.heightAnchor.constraint(equalTo: scrollContentView.heightAnchor)
        fit.priority = .defaultLow

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: confirmContainer.topAnchor),
            fit,
            scrollContentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            scrollContentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            scrollContentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            scrollContentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            scrollContentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            contentStack.topAnchor.constraint(equalTo: scrollContentView.topAnchor),
            contentStack.bottomAnchor.constraint(equalTo: scrollContentView.bottomAnchor),
            contentStack.leadingAnchor.constraint(equalTo: scrollContentView.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: scrollContentView.trailingAnchor),
        ])

        contentStack.addArrangedSubview(makeSwitchRow())
        contentStack.addArrangedSubview(makeDivider())
        contentStack.addArrangedSubview(OptionGroupView(title: "Mode",
                                                        items: [("a", "Option A"), ("b", "Option B")],
                                                        idPrefix: "sheet_mode"))
        contentStack.addArrangedSubview(makeDivider())
        contentStack.addArrangedSubview(OptionGroupView(title: "Preference",
                                                        items: [("off", "OFF"), ("one", "ONE"), ("two", "TWO")],
                                                        idPrefix: "sheet_pref"))
        contentStack.addArrangedSubview(makeCirclesSection())
    }

    private func makeSwitchRow() -> UIView {
        let row = UIView()
        let label = UILabel()
        label.text = "Enabled"
        label.font = .systemFont(ofSize: 16, weight: .medium)
        let toggle = UISwitch()
        toggle.isOn = true
        toggle.accessibilityIdentifier = "sheet_toggle_switch"
        [label, toggle].forEach { $0.translatesAutoresizingMaskIntoConstraints = false; row.addSubview($0) }
        row.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            row.heightAnchor.constraint(equalToConstant: 54),
            label.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 16),
            label.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            toggle.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -16),
            toggle.centerYAnchor.constraint(equalTo: row.centerYAnchor),
        ])
        return row
    }

    private func makeDivider() -> UIView {
        let holder = UIView()
        let line = UIView()
        line.backgroundColor = .separator
        holder.addSubview(line)
        [holder, line].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        NSLayoutConstraint.activate([
            holder.heightAnchor.constraint(equalToConstant: 1),
            line.topAnchor.constraint(equalTo: holder.topAnchor),
            line.bottomAnchor.constraint(equalTo: holder.bottomAnchor),
            line.leadingAnchor.constraint(equalTo: holder.leadingAnchor, constant: 16),
            line.trailingAnchor.constraint(equalTo: holder.trailingAnchor),
        ])
        return holder
    }

    private func makeCirclesSection() -> UIView {
        let section = UIView()
        let grid = UIStackView()
        grid.axis = .vertical
        grid.spacing = 24
        grid.alignment = .center
        let rows = [[("1", "ALPHA", "08:00"), ("2", "BRAVO", "11:00")],
                    [("3", "CHARLIE", "14:00"), ("4", "DELTA", "70:00")]]
        for pair in rows {
            let row = UIStackView()
            row.axis = .horizontal
            row.spacing = 32
            for (n, title, value) in pair {
                row.addArrangedSubview(CircleView(idSuffix: n, title: title, value: value))
            }
            grid.addArrangedSubview(row)
        }
        section.addSubview(grid)
        [section, grid].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        NSLayoutConstraint.activate([
            grid.topAnchor.constraint(equalTo: section.topAnchor, constant: 24),
            grid.bottomAnchor.constraint(equalTo: section.bottomAnchor, constant: -24),
            grid.centerXAnchor.constraint(equalTo: section.centerXAnchor),
        ])
        return section
    }

    private func pin(_ child: UIView, to parent: UIView) {
        child.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            child.topAnchor.constraint(equalTo: parent.topAnchor),
            child.bottomAnchor.constraint(equalTo: parent.bottomAnchor),
            child.leadingAnchor.constraint(equalTo: parent.leadingAnchor),
            child.trailingAnchor.constraint(equalTo: parent.trailingAnchor),
        ])
    }
}

// MARK: - Option group (title + pill buttons; every button holds its own label subview)

private final class OptionGroupView: UIView {
    init(title: String, items: [(id: String, title: String)], idPrefix: String) {
        super.init(frame: .zero)
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        let buttons = UIStackView()
        buttons.axis = .horizontal
        buttons.spacing = 12
        buttons.distribution = .fillEqually
        for item in items {
            let button = UIButton(type: .custom)
            button.accessibilityIdentifier = "\(idPrefix)_\(item.id)"
            button.layer.cornerRadius = 8
            button.layer.borderWidth = 1
            button.layer.borderColor = UIColor.separator.cgColor
            let label = UILabel()
            label.text = item.title
            label.font = .systemFont(ofSize: 15, weight: .medium)
            label.isUserInteractionEnabled = false
            label.translatesAutoresizingMaskIntoConstraints = false
            button.addSubview(label)
            NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(equalTo: button.centerXAnchor),
                label.centerYAnchor.constraint(equalTo: button.centerYAnchor),
                button.heightAnchor.constraint(equalToConstant: 41),
            ])
            buttons.addArrangedSubview(button)
        }
        [titleLabel, buttons].forEach { $0.translatesAutoresizingMaskIntoConstraints = false; addSubview($0) }
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            buttons.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            buttons.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            buttons.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            buttons.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

// MARK: - Circle (ring + value + title)

private final class CircleView: UIView {
    init(idSuffix: String, title: String, value: String) {
        super.init(frame: .zero)
        accessibilityIdentifier = "sheet_circle_\(idSuffix)"

        let ring = UIView()
        ring.layer.cornerRadius = 60
        ring.layer.borderWidth = 6
        ring.layer.borderColor = UIColor.systemBlue.cgColor
        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = .systemFont(ofSize: 26, weight: .bold)
        valueLabel.accessibilityIdentifier = "sheet_circle_\(idSuffix)_value"
        let setLabel = UILabel()
        setLabel.text = "SET"
        setLabel.font = .systemFont(ofSize: 13)
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        titleLabel.accessibilityIdentifier = "sheet_circle_\(idSuffix)_title"

        let inner = UIStackView(arrangedSubviews: [valueLabel, setLabel])
        inner.axis = .vertical
        inner.alignment = .center
        ring.addSubview(inner)
        [ring, titleLabel, inner].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        addSubview(ring)
        addSubview(titleLabel)
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 120),
            heightAnchor.constraint(equalToConstant: 148),
            ring.topAnchor.constraint(equalTo: topAnchor),
            ring.leadingAnchor.constraint(equalTo: leadingAnchor),
            ring.widthAnchor.constraint(equalToConstant: 120),
            ring.heightAnchor.constraint(equalToConstant: 120),
            inner.centerXAnchor.constraint(equalTo: ring.centerXAnchor),
            inner.centerYAnchor.constraint(equalTo: ring.centerYAnchor),
            titleLabel.topAnchor.constraint(equalTo: ring.bottomAnchor, constant: 8),
            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
