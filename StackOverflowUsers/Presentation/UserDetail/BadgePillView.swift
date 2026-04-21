import UIKit

// MARK: - BadgePillView

@MainActor
final class BadgePillView: UIStackView {

    enum Kind: String {
        case gold, silver, bronze

        var tint: UIColor {
            switch self {
            case .gold:   return .systemYellow
            case .silver: return .systemGray
            case .bronze: return .systemBrown
            }
        }
    }

    // MARK: - Subviews

    private let dot: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 6
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let countLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .callout)
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    // MARK: - Init

    init(kind: Kind, count: Int) {
        super.init(frame: .zero)
        axis = .horizontal
        spacing = 6
        alignment = .center
        isAccessibilityElement = true

        dot.backgroundColor = kind.tint
        countLabel.text = "\(count) \(kind.rawValue)"
        accessibilityLabel = "\(count) \(kind.rawValue) badges"

        addArrangedSubview(dot)
        addArrangedSubview(countLabel)

        NSLayoutConstraint.activate([
            dot.widthAnchor.constraint(equalToConstant: 12),
            dot.heightAnchor.constraint(equalToConstant: 12)
        ])
    }

    required init(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
