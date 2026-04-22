import UIKit

// MARK: - FilterHeaderView

@MainActor
final class FilterHeaderView: UIView {

    var onFilterChanged: ((UserListViewModel.Filter) -> Void)?

    // MARK: - Subviews

    private let segmentedControl: UISegmentedControl = {
        let control = UISegmentedControl(items: ["All", "Followed"])
        control.selectedSegmentIndex = 0
        control.selectedSegmentTintColor = StackOverflowPalette.accent
        control.setTitleTextAttributes(
            [.foregroundColor: StackOverflowPalette.textPrimary],
            for: .normal
        )
        control.setTitleTextAttributes(
            [.foregroundColor: StackOverflowPalette.onStrongColor],
            for: .selected
        )
        control.translatesAutoresizingMaskIntoConstraints = false
        control.accessibilityIdentifier = "filter-control"
        return control
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = StackOverflowPalette.appBackground
        addSubview(segmentedControl)

        let leading  = segmentedControl.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16)
        let trailing = segmentedControl.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16)

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
