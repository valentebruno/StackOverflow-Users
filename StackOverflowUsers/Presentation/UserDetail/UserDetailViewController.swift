import UIKit

// MARK: - UserDetailViewController

@MainActor
final class UserDetailViewController: UIViewController {

    // MARK: - Dependencies

    private let viewModel: UserDetailViewModel
    private let imageLoader: ImageLoading
    private let urlOpener: (URL) -> Void

    // MARK: - Subviews

    private let scrollView: UIScrollView = {
        let view = UIScrollView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.alwaysBounceVertical = true
        return view
    }()

    private let contentStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let avatarImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.layer.cornerRadius = 60
        view.backgroundColor = StackOverflowPalette.componentAltBackground
        view.translatesAutoresizingMaskIntoConstraints = false
        view.accessibilityLabel = "User avatar"
        return view
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .largeTitle)
        label.textColor = StackOverflowPalette.textPrimary
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()

    private let reputationLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .title3)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = StackOverflowPalette.textSecondary
        label.textAlignment = .center
        return label
    }()

    private let locationLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = StackOverflowPalette.textTertiary
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let acceptRateLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .footnote)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = StackOverflowPalette.textSecondary
        label.textAlignment = .center
        return label
    }()

    private let badgesStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .equalSpacing
        stack.spacing = 24
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let profileButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "Open on Stack Overflow"
        config.image = UIImage(systemName: "arrow.up.right.square")
        config.imagePadding = 8
        config.cornerStyle = .large
        config.baseBackgroundColor = StackOverflowPalette.primaryAction
        config.baseForegroundColor = StackOverflowPalette.onStrongColor
        let button = UIButton(configuration: config)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.accessibilityIdentifier = "open-profile-button"
        return button
    }()

    private var imageLoadTask: Task<Void, Never>?

    // MARK: - Init

    init(
        viewModel: UserDetailViewModel,
        imageLoader: ImageLoading,
        urlOpener: @escaping (URL) -> Void
    ) {
        self.viewModel = viewModel
        self.imageLoader = imageLoader
        self.urlOpener = urlOpener
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    deinit {
        imageLoadTask?.cancel()
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = StackOverflowPalette.appBackground
        title = viewModel.displayName
        navigationItem.largeTitleDisplayMode = .never
        setupLayout()
        configure()
        profileButton.addTarget(self, action: #selector(openProfileTapped), for: .touchUpInside)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard UIAccessibility.isVoiceOverRunning else { return }
        UIAccessibility.post(
            notification: .screenChanged,
            argument: "Profile of \(viewModel.displayName). \(viewModel.formattedReputation)."
        )
    }

    // MARK: - Setup

    private func setupLayout() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)

        contentStack.addArrangedSubview(avatarImageView)
        contentStack.addArrangedSubview(nameLabel)
        contentStack.addArrangedSubview(reputationLabel)
        contentStack.addArrangedSubview(acceptRateLabel)
        contentStack.addArrangedSubview(badgesStack)
        contentStack.addArrangedSubview(locationLabel)
        contentStack.addArrangedSubview(profileButton)

        contentStack.setCustomSpacing(20, after: avatarImageView)
        contentStack.setCustomSpacing(24, after: badgesStack)

        // On iPad the scroll view stretches the full window width; cap the content at
        // a readable measure and centre it while still letting it shrink on iPhone.
        let widthToFrame = contentStack.widthAnchor.constraint(
            equalTo: scrollView.frameLayoutGuide.widthAnchor,
            constant: -48
        )
        widthToFrame.priority = .defaultHigh

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 32),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -32),
            contentStack.centerXAnchor.constraint(equalTo: scrollView.contentLayoutGuide.centerXAnchor),
            contentStack.widthAnchor.constraint(lessThanOrEqualToConstant: 560),
            widthToFrame,

            avatarImageView.widthAnchor.constraint(equalToConstant: 120),
            avatarImageView.heightAnchor.constraint(equalToConstant: 120)
        ])
    }

    private func configure() {
        nameLabel.text       = viewModel.displayName
        reputationLabel.text = viewModel.formattedReputation
        locationLabel.text   = viewModel.location
        locationLabel.isHidden = viewModel.location == nil
        acceptRateLabel.text = viewModel.formattedAcceptRate
        acceptRateLabel.isHidden = viewModel.formattedAcceptRate == nil
        profileButton.isHidden = viewModel.profileURL == nil

        configureBadges()
        avatarImageView.image = InitialsImageGenerator.image(
            for: viewModel.displayName,
            size: CGSize(width: 120, height: 120)
        )
        loadRemoteAvatar()
    }

    private func configureBadges() {
        badgesStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        guard viewModel.hasBadges else {
            badgesStack.isHidden = true
            return
        }
        badgesStack.isHidden = false
        badgesStack.addArrangedSubview(BadgePillView(kind: .gold,   count: viewModel.goldBadges))
        badgesStack.addArrangedSubview(BadgePillView(kind: .silver, count: viewModel.silverBadges))
        badgesStack.addArrangedSubview(BadgePillView(kind: .bronze, count: viewModel.bronzeBadges))
    }

    private func loadRemoteAvatar() {
        guard let url = viewModel.profileImageURL else { return }
        imageLoadTask?.cancel()
        let placeholder = avatarImageView.image
        imageLoadTask = Task { @MainActor [weak self] in
            let loaded = await self?.imageLoader.image(for: url)
            guard !Task.isCancelled, let self else { return }
            self.avatarImageView.image = loaded ?? placeholder
        }
    }

    // MARK: - Actions

    @objc private func openProfileTapped() {
        guard let url = viewModel.profileURL else { return }
        urlOpener(url)
    }
}
