import UIKit

// MARK: - EmptyStateView

@MainActor
final class EmptyStateView: UIView {

    // MARK: - Output

    var onRetry: (() -> Void)?

    // MARK: - Subviews

    private let iconImageView: UIImageView = {
        let config = UIImage.SymbolConfiguration(pointSize: 48, weight: .regular)
        let iv = UIImageView(image: UIImage(systemName: "wifi.exclamationmark", withConfiguration: config))
        iv.tintColor = .secondaryLabel
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        label.accessibilityIdentifier = "empty-state-title"
        return label
    }()

    private let messageLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .body)
        label.textColor = .secondaryLabel
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let retryButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "Try Again"
        config.cornerStyle = .capsule
        let button = UIButton(configuration: config)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
        retryButton.addTarget(self, action: #selector(retryTapped), for: .touchUpInside)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Configure

    func configure(
        title: String,
        message: String,
        showsRetry: Bool = true,
        systemImage: String = "wifi.exclamationmark"
    ) {
        let config = UIImage.SymbolConfiguration(pointSize: 48, weight: .regular)
        iconImageView.image = UIImage(systemName: systemImage, withConfiguration: config)
        titleLabel.text = title
        messageLabel.text = message
        retryButton.isHidden = !showsRetry
    }

    // MARK: - Actions

    @objc private func retryTapped() {
        onRetry?()
    }

    // MARK: - Layout

    private func setupLayout() {
        let stack = UIStackView(arrangedSubviews: [iconImageView, titleLabel, messageLabel, retryButton])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 12
        stack.setCustomSpacing(20, after: messageLabel)
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor, constant: -24)
        ])
    }
}
