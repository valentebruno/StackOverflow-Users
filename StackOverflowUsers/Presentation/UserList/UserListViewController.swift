import UIKit

// MARK: - UserListViewController

final class UserListViewController: UIViewController {

    private let viewModel: UserListViewModel

    init(viewModel: UserListViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "StackOverflow Users"
        view.backgroundColor = .systemBackground
    }
}
