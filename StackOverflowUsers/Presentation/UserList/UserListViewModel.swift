import Foundation

// MARK: - UserListViewModel

@MainActor
final class UserListViewModel {

    // MARK: - ViewState

    enum ViewState: Equatable {
        case idle
        case loading
        case loaded([UserCellModel])
        case failed(AppError)
    }

    // MARK: - Output

    private(set) var state: ViewState = .idle {
        didSet { onStateChange?(state) }
    }

    var onStateChange: ((ViewState) -> Void)?

    // MARK: - Dependencies

    private let userService: UserServiceProtocol
    private let followRepository: FollowRepositoryProtocol

    init(
        userService: UserServiceProtocol,
        followRepository: FollowRepositoryProtocol
    ) {
        self.userService = userService
        self.followRepository = followRepository
    }
}
