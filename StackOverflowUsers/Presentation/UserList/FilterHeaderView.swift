import UIKit

// MARK: - FilterHeaderView

@MainActor
final class FilterHeaderView: UIView {

    var onFilterChanged: ((UserListViewModel.Filter) -> Void)?

    // MARK: - Subviews

    private let segmentedControl: UISegmentedControl = {
        let control = UISegmentedControl(items: ["All", "Followed"])
        control.selectedSegmentIndex = 0
        control.translatesAutoresizingMaskIntoConstraints = false
        control.accessibilityIdentifier = "filter-control"
        return control
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        autoresizingMask = .flexibleWidth
        addSubview(segmentedControl)

        NSLayoutConstraint.activate([
            segmentedControl.centerYAnchor.constraint(equalTo: centerYAnchor),
            segmentedControl.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor, constant: 8),
            segmentedControl.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor, constant: -8)
        ])

        segmentedControl.addTarget(self, action: #selector(selectionChanged), for: .valueChanged)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Actions

    @objc private func selectionChanged() {
        let filter: UserListViewModel.Filter = segmentedControl.selectedSegmentIndex == 1 ? .followed : .all
        onFilterChanged?(filter)
    }
}
