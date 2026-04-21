import UIKit

// MARK: - UserCell

@MainActor
final class UserCell: UITableViewCell {

    static let reuseIdentifier = "UserCell"

    // MARK: - State

    private var imageLoadTask: Task<Void, Never>?
    private var onFollowTapped: (() -> Void)?

    // MARK: - Subviews

    private let avatarImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 22
        iv.backgroundColor = .secondarySystemFill
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let reputationLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .footnote)
        label.textColor = .secondaryLabel
        label.adjustsFontForContentSizeCategory = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let followButton: UIButton = {
        var config = UIButton.Configuration.bordered()
        config.cornerStyle = .capsule
        config.buttonSize = .small
        let button = UIButton(configuration: config)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        return button
    }()

    private let followedIndicator: UIImageView = {
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        let iv = UIImageView(image: UIImage(systemName: "checkmark.seal.fill", withConfiguration: config))
        iv.tintColor = .systemBlue
        iv.isHidden = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.setContentHuggingPriority(.required, for: .horizontal)
        iv.isAccessibilityElement = false
        return iv
    }()

    // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        isAccessibilityElement = true
        accessibilityTraits = .button
        setupLayout()
        followButton.addTarget(self, action: #selector(followButtonTapped), for: .touchUpInside)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Reuse

    override func prepareForReuse() {
        super.prepareForReuse()
        imageLoadTask?.cancel()
        imageLoadTask = nil
        avatarImageView.image = nil
        nameLabel.text = nil
        reputationLabel.text = nil
        followedIndicator.isHidden = true
        onFollowTapped = nil
    }

    // MARK: - Configure

    func configure(
        with model: UserCellModel,
        imageLoader: ImageLoading,
        onFollowTapped: @escaping () -> Void
    ) {
        self.onFollowTapped = onFollowTapped

        nameLabel.text = model.displayName
        reputationLabel.text = model.formattedReputation
        followedIndicator.isHidden = !model.isFollowed
        updateFollowButton(isFollowed: model.isFollowed, name: model.displayName)
        updateAccessibility(model: model)

        let placeholder = InitialsImageGenerator.image(for: model.displayName)
        avatarImageView.image = placeholder

        guard let url = model.profileImageURL else { return }

        imageLoadTask = Task { @MainActor [weak self] in
            let loaded = await imageLoader.image(for: url)
            guard !Task.isCancelled, let self else { return }
            self.avatarImageView.image = loaded ?? placeholder
        }
    }

    // MARK: - Accessibility

    private func updateAccessibility(model: UserCellModel) {
        let followState = model.isFollowed ? "Followed" : "Not followed"
        accessibilityLabel = "\(model.displayName), \(model.formattedReputation), \(followState)"

        let actionTitle = model.isFollowed ? "Unfollow" : "Follow"
        accessibilityCustomActions = [
            UIAccessibilityCustomAction(name: actionTitle) { [weak self] _ in
                self?.onFollowTapped?()
                return true
            }
        ]
    }

    // MARK: - Actions

    @objc private func followButtonTapped() {
        UISelectionFeedbackGenerator().selectionChanged()
        onFollowTapped?()
    }

    // MARK: - Layout

    private func updateFollowButton(isFollowed: Bool, name: String) {
        var config: UIButton.Configuration = isFollowed ? .tinted() : .bordered()
        config.cornerStyle = .capsule
        config.buttonSize = .small
        config.title = isFollowed ? "Unfollow" : "Follow"
        config.image = UIImage(systemName: isFollowed ? "person.crop.circle.badge.minus" : "person.crop.circle.badge.plus")
        config.imagePadding = 4
        config.baseForegroundColor = isFollowed ? .systemRed : .systemBlue
        config.baseBackgroundColor = isFollowed ? .systemRed.withAlphaComponent(0.12) : .clear
        followButton.configuration = config
        followButton.accessibilityLabel = isFollowed ? "Unfollow \(name)" : "Follow \(name)"
    }

    private func setupLayout() {
        let textStack = UIStackView(arrangedSubviews: [nameLabel, reputationLabel])
        textStack.axis = .vertical
        textStack.spacing = 2
        textStack.translatesAutoresizingMaskIntoConstraints = false

        let trailingStack = UIStackView(arrangedSubviews: [followedIndicator, followButton])
        trailingStack.axis = .horizontal
        trailingStack.spacing = 8
        trailingStack.alignment = .center
        trailingStack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(avatarImageView)
        contentView.addSubview(textStack)
        contentView.addSubview(trailingStack)

        NSLayoutConstraint.activate([
            avatarImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            avatarImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 44),
            avatarImageView.heightAnchor.constraint(equalToConstant: 44),

            textStack.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 12),
            textStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            textStack.trailingAnchor.constraint(lessThanOrEqualTo: trailingStack.leadingAnchor, constant: -12),

            trailingStack.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            trailingStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            followedIndicator.widthAnchor.constraint(equalToConstant: 22),
            followedIndicator.heightAnchor.constraint(equalToConstant: 22),

            contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 72)
        ])
    }
}

// MARK: - UserCellModel

struct UserCellModel: Hashable, Sendable {
    let userID: Int
    let displayName: String
    let profileImageURL: URL?
    let reputation: Int
    let isFollowed: Bool

    var formattedReputation: String {
        Self.formatter.string(from: NSNumber(value: reputation)).map { "\($0) rep" } ?? "\(reputation) rep"
    }

    private static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()
}
