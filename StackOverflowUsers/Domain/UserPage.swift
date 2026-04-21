import Foundation

// MARK: - UserPage

struct UserPage: Equatable, Sendable {
    let users: [User]
    let hasMore: Bool
}
