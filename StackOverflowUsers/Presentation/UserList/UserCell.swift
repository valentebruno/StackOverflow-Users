import UIKit

// MARK: - UserCell

@MainActor
final class UserCell: UITableViewCell {

    static let reuseIdentifier = "UserCell"

    // MARK: - State

    private var imageLoadTask: Task<Void, Never>?
    private var onFollowTapped: (() -> Void)?
    private var lastConfiguredModel: UserCellModel?

    // MARK: - Subviews

    private let avatarImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 22
        iv.backgroundColor = StackOverflowPalette.componentAltBackground
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let avatarContainerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 24
        view.layer.borderWidth = 1
        view.layer.borderColor = StackOverflowPalette.separator.cgColor
        view.backgroundColor = StackOverflowPalette.contentBackground
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        StackOverflowTypography.apply(.body3, weight: .regular, to: label)
        label.textColor = StackOverflowPalette.textPrimary
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let reputationLabel: UILabel = {
        let label = UILabel()
        StackOverflowTypography.apply(.body1, weight: .regular, to: label)
        label.textColor = StackOverflowPalette.textSecondary
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

    private let separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = StackOverflowPalette.separator
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = StackOverflowPalette.contentBackground
        contentView.backgroundColor = StackOverflowPalette.contentBackground
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
        updateAvatarRing(isFollowed: false)
        onFollowTapped = nil
        lastConfiguredModel = nil
    }

    // MARK: - Configure

    func configure(
        with model: UserCellModel,
        imageLoader: ImageLoading,
        onFollowTapped: @escaping () -> Void
    ) {
        imageLoadTask?.cancel()
        imageLoadTask = nil

        let previousModel = lastConfiguredModel
        self.onFollowTapped = onFollowTapped

        nameLabel.text = model.displayName
        reputationLabel.text = model.formattedReputation
        updateAvatarRing(isFollowed: model.isFollowed)
        updateFollowButton(isFollowed: model.isFollowed, name: model.displayName)
        updateAccessibility(model: model)
        announceFollowChangeIfNeeded(previous: previousModel, current: model)
        lastConfiguredModel = model
        accessibilityIdentifier = "user-cell-\(model.userID)"
        followButton.accessibilityIdentifier = "follow-button-\(model.userID)"

        let placeholder = InitialsImageGenerator.image(for: model.displayName)
        avatarImageView.image = placeholder

        guard let url = model.profileImageURL else { return }

        imageLoadTask = Task { @MainActor [weak self, backoff = Self.scrollBackoffNanoseconds] in
            // Brief backoff so fast scrolling (which cancels + re-requests the same cell
            // many times per second) doesn't spray the network with never-rendered fetches.
            try? await Task.sleep(nanoseconds: backoff)
            guard !Task.isCancelled else { return }
            let loaded = await imageLoader.image(for: url)
            guard !Task.isCancelled, let self else { return }
            self.avatarImageView.image = loaded ?? placeholder
        }
    }

    private static let scrollBackoffNanoseconds: UInt64 = 150_000_000

    // MARK: - Accessibility

    private func announceFollowChangeIfNeeded(
        previous: UserCellModel?,
        current: UserCellModel
    ) {
        guard let previous,
              previous.userID == current.userID,
              previous.isFollowed != current.isFollowed,
              UIAccessibility.isVoiceOverRunning
        else { return }

        let message = current.isFollowed
            ? "Now following \(current.displayName)"
            : "Unfollowed \(current.displayName)"
        UIAccessibility.post(notification: .announcement, argument: message)
    }

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
        config.titleTextAttributesTransformer = StackOverflowTypography.buttonTextTransformer(.body1)
        config.baseForegroundColor = isFollowed ? StackOverflowPalette.danger : StackOverflowPalette.primaryAction
        config.baseBackgroundColor = isFollowed
            ? StackOverflowPalette.danger.withAlphaComponent(0.12)
            : .clear
        followButton.configuration = config
        followButton.accessibilityLabel = isFollowed ? "Unfollow \(name)" : "Follow \(name)"
    }

    private func updateAvatarRing(isFollowed: Bool) {
        avatarContainerView.layer.borderColor = (isFollowed
            ? StackOverflowPalette.accent
            : StackOverflowPalette.separator
        ).cgColor
    }

    private let textStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 2
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let trailingStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let outerStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private func setupLayout() {
        avatarContainerView.addSubview(avatarImageView)

        textStack.addArrangedSubview(nameLabel)
        textStack.addArrangedSubview(reputationLabel)

        trailingStack.addArrangedSubview(followButton)

        outerStack.addArrangedSubview(avatarContainerView)
        outerStack.addArrangedSubview(textStack)
        outerStack.addArrangedSubview(trailingStack)

        contentView.addSubview(outerStack)
        contentView.addSubview(separatorView)

        NSLayoutConstraint.activate([
            outerStack.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            outerStack.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            outerStack.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor, constant: 8),
            outerStack.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor, constant: -8),

            avatarContainerView.widthAnchor.constraint(equalToConstant: 48),
            avatarContainerView.heightAnchor.constraint(equalToConstant: 48),

            avatarImageView.centerXAnchor.constraint(equalTo: avatarContainerView.centerXAnchor),
            avatarImageView.centerYAnchor.constraint(equalTo: avatarContainerView.centerYAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 44),
            avatarImageView.heightAnchor.constraint(equalToConstant: 44),

            separatorView.leadingAnchor.constraint(equalTo: textStack.leadingAnchor),
            separatorView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            separatorView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separatorView.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale),

            contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 72)
        ])

        applyContentSizeLayout(for: traitCollection)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateAvatarRing(isFollowed: lastConfiguredModel?.isFollowed == true)
        separatorView.backgroundColor = StackOverflowPalette.separator

        if traitCollection.preferredContentSizeCategory != previousTraitCollection?.preferredContentSizeCategory {
            applyContentSizeLayout(for: traitCollection)
        }
    }

    private func applyContentSizeLayout(for traits: UITraitCollection) {
        if traits.preferredContentSizeCategory.isAccessibilityCategory {
            outerStack.axis = .vertical
            outerStack.alignment = .leading
            outerStack.spacing = 8
            trailingStack.axis = .horizontal
            nameLabel.numberOfLines = 0
        } else {
            outerStack.axis = .horizontal
            outerStack.alignment = .center
            outerStack.spacing = 12
            trailingStack.axis = .horizontal
            nameLabel.numberOfLines = 1
        }
    }
}
