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

        // Pin to the view itself (not layoutMarginsGuide) and lower the trailing
        // priority — a table-header view is briefly installed with zero width, which
        // would otherwise force UIKit to break one of the edge constraints out loud.
        let leading  = segmentedControl.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16)
        let trailing = segmentedControl.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16)
        trailing.priority = UILayoutPriority(999)

        NSLayoutConstraint.activate([
            segmentedControl.centerYAnchor.constraint(equalTo: centerYAnchor),
            leading,
            trailing
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
