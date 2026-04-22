import UIKit

// MARK: - UserListViewController

@MainActor
final class UserListViewController: UIViewController {

    // MARK: - Sections

    private enum Section: Hashable { case main }

    // MARK: - Dependencies

    private let viewModel: UserListViewModel
    private let imageLoader: ImageLoading
    var onSelectUser: ((User) -> Void)?

    // MARK: - Subviews

    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .plain)
        table.backgroundColor = StackOverflowPalette.appBackground
        table.separatorColor = StackOverflowPalette.separator
        table.register(UserCell.self, forCellReuseIdentifier: UserCell.reuseIdentifier)
        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = 72
        table.separatorInset = UIEdgeInsets(top: 0, left: 72, bottom: 0, right: 0)
        table.translatesAutoresizingMaskIntoConstraints = false
        return table
    }()

    private lazy var loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()

    private lazy var emptyStateView: EmptyStateView = {
        let view = EmptyStateView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        view.backgroundColor = StackOverflowPalette.appBackground
        view.onRetry = { [weak self] in self?.viewModel.retry() }
        return view
    }()

    private lazy var refreshControl: UIRefreshControl = {
        let control = UIRefreshControl()
        control.addTarget(self, action: #selector(pullToRefresh), for: .valueChanged)
        return control
    }()

    private lazy var filterHeaderView: FilterHeaderView = {
        let header = FilterHeaderView()
        header.translatesAutoresizingMaskIntoConstraints = false
        header.onFilterChanged = { [weak self] filter in
            self?.viewModel.setFilter(filter)
        }
        return header
    }()

    private lazy var staleBannerLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .footnote)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = StackOverflowPalette.black600
        label.textAlignment = .center
        label.numberOfLines = 2
        label.backgroundColor = StackOverflowPalette.warningBackground
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        return label
    }()

    // MARK: - State

    private var itemModels: [Int: UserCellModel] = [:]
    private lazy var dataSource = makeDataSource()
    private var staleBannerHeightConstraint: NSLayoutConstraint?

    // MARK: - Init

    init(viewModel: UserListViewModel, imageLoader: ImageLoading) {
        self.viewModel = viewModel
        self.imageLoader = imageLoader
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Stack Overflow Users"
        view.backgroundColor = StackOverflowPalette.appBackground
        setupViews()
        bindViewModel()
        viewModel.load()
    }

    // MARK: - Setup

    private func setupViews() {
        let staleHeight = staleBannerLabel.heightAnchor.constraint(equalToConstant: 0)
        staleBannerHeightConstraint = staleHeight

        view.addSubview(staleBannerLabel)
        view.addSubview(filterHeaderView)
        view.addSubview(tableView)
        view.addSubview(emptyStateView)
        view.addSubview(loadingIndicator)

        tableView.dataSource = dataSource
        tableView.delegate = self
        tableView.refreshControl = refreshControl

        NSLayoutConstraint.activate([
            staleBannerLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            staleBannerLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            staleBannerLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            staleHeight,

            filterHeaderView.topAnchor.constraint(equalTo: staleBannerLabel.bottomAnchor),
            filterHeaderView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            filterHeaderView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            filterHeaderView.heightAnchor.constraint(equalToConstant: 64),

            tableView.topAnchor.constraint(equalTo: filterHeaderView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyStateView.topAnchor.constraint(equalTo: filterHeaderView.bottomAnchor),
            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptyStateView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func bindViewModel() {
        viewModel.onStateChange = { [weak self] state in
            self?.render(state)
        }
    }

    // MARK: - Render

    private func render(_ state: UserListViewModel.ViewState) {
        switch state {
        case .idle:
            break

        case .loading:
            if dataSource.snapshot().numberOfItems == 0 {
                tableView.isHidden = true
                emptyStateView.isHidden = true
                loadingIndicator.startAnimating()
            }

        case .loaded(let models):
            loadingIndicator.stopAnimating()
            refreshControl.endRefreshing()
            tableView.isHidden = false
            emptyStateView.isHidden = true
            setStaleBanner(visible: false)
            apply(models, animated: true)

        case .stale(let models, let error):
            loadingIndicator.stopAnimating()
            refreshControl.endRefreshing()
            tableView.isHidden = false
            emptyStateView.isHidden = true
            setStaleBanner(visible: true, error: error)
            apply(models, animated: false)

        case .empty(let reason):
            loadingIndicator.stopAnimating()
            refreshControl.endRefreshing()
            setStaleBanner(visible: false)
            apply([], animated: true)
            tableView.isHidden = false
            emptyStateView.isHidden = false
            emptyStateView.configure(
                title:       UserListStateCopy.emptyTitle(for: reason),
                message:     UserListStateCopy.emptyMessage(for: reason),
                showsRetry:  false,
                systemImage: "person.2.slash"
            )

        case .failed(let error, let stale):
            loadingIndicator.stopAnimating()
            refreshControl.endRefreshing()
            setStaleBanner(visible: false)

            if stale.isEmpty {
                apply([], animated: true)
                tableView.isHidden = false
                emptyStateView.isHidden = false
                emptyStateView.configure(
                    title:   UserListStateCopy.errorTitle(for: error),
                    message: error.userFacingMessage
                )
            } else {
                tableView.isHidden = false
                emptyStateView.isHidden = true
                apply(stale, animated: false)
                presentErrorBanner(for: error)
            }
        }
    }

    private func setStaleBanner(visible: Bool, error: AppError? = nil) {
        staleBannerLabel.isHidden = !visible
        staleBannerHeightConstraint?.constant = visible ? 36 : 0
        guard visible else { return }
        let reason = error.map(UserListStateCopy.errorTitle(for:)) ?? "Offline"
        staleBannerLabel.text = "Showing saved users · \(reason)"
    }

    private func presentErrorBanner(for error: AppError) {
        let alert = UIAlertController(
            title: UserListStateCopy.errorTitle(for: error),
            message: error.userFacingMessage,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Retry", style: .default) { [weak self] _ in
            self?.viewModel.retry()
        })
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel))
        present(alert, animated: true)
    }

    // MARK: - Diffable Data Source

    private func makeDataSource() -> UITableViewDiffableDataSource<Section, Int> {
        UITableViewDiffableDataSource(tableView: tableView) { [weak self] tableView, indexPath, userID in
            guard let self,
                  let model = self.itemModels[userID],
                  let cell = tableView.dequeueReusableCell(
                    withIdentifier: UserCell.reuseIdentifier,
                    for: indexPath
                  ) as? UserCell
            else { return UITableViewCell() }

            cell.configure(
                with: model,
                imageLoader: self.imageLoader,
                onFollowTapped: { [weak self] in
                    self?.viewModel.toggleFollow(userID: userID)
                }
            )
            return cell
        }
    }

    private func apply(_ models: [UserCellModel], animated: Bool) {
        let changedIDs = models.compactMap { model -> Int? in
            guard let previous = itemModels[model.userID], previous != model else { return nil }
            return model.userID
        }

        itemModels = Dictionary(uniqueKeysWithValues: models.map { ($0.userID, $0) })

        var snapshot = NSDiffableDataSourceSnapshot<Section, Int>()
        snapshot.appendSections([.main])
        snapshot.appendItems(models.map(\.userID), toSection: .main)
        if !changedIDs.isEmpty {
            snapshot.reconfigureItems(changedIDs)
        }
        dataSource.apply(snapshot, animatingDifferences: animated)
    }

    // MARK: - Actions

    @objc private func pullToRefresh() {
        viewModel.load()
    }
}

// MARK: - UITableViewDelegate

extension UserListViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let userID = dataSource.itemIdentifier(for: indexPath),
              let user = viewModel.user(withID: userID)
        else { return }
        onSelectUser?(user)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let threshold: CGFloat = 240
        let distanceToBottom = scrollView.contentSize.height - (scrollView.contentOffset.y + scrollView.bounds.height)
        guard scrollView.contentSize.height > 0, distanceToBottom < threshold else { return }
        viewModel.loadNextPage()
    }

    func tableView(
        _ tableView: UITableView,
        leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        guard let userID = dataSource.itemIdentifier(for: indexPath),
              let model  = itemModels[userID]
        else { return nil }

        let title = model.isFollowed ? "Unfollow" : "Follow"
        let style: UIContextualAction.Style = model.isFollowed ? .destructive : .normal
        let action = UIContextualAction(style: style, title: title) { [weak self] _, _, done in
            self?.viewModel.toggleFollow(userID: userID)
            done(true)
        }
        action.backgroundColor = model.isFollowed ? StackOverflowPalette.danger : StackOverflowPalette.primaryAction
        action.image = UIImage(systemName: model.isFollowed ? "person.crop.circle.badge.minus" : "person.crop.circle.badge.plus")
        return UISwipeActionsConfiguration(actions: [action])
    }
}
