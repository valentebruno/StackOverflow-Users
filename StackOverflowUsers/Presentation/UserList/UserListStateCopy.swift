import Foundation

// MARK: - UserListStateCopy

enum UserListStateCopy {

    // MARK: - Empty

    static func emptyTitle(for reason: UserListViewModel.EmptyReason) -> String {
        switch reason {
        case .nothingFollowed: return "No followed users yet"
        }
    }

    static func emptyMessage(for reason: UserListViewModel.EmptyReason) -> String {
        switch reason {
        case .nothingFollowed:
            return "Tap Follow on any user to keep a shortcut here."
        }
    }

    // MARK: - Error

    static func errorTitle(for error: AppError) -> String {
        switch error {
        case .networkUnavailable: return "You're offline"
        case .serverError:        return "Server trouble"
        case .apiError:           return "API error"
        case .decodingError:      return "Unexpected response"
        case .noResults:          return "No users found"
        }
    }
}
